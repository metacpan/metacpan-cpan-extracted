#include "backtrace.h"
#include <vector>
#include <xs/catch.h>
#include <xs/Stash.h>
#include "PerlTrace.h"
#include <iostream>

using namespace panda;
using panda::Backtrace;
using xs::my_perl;

#ifndef CvHASGV
    // for perls < 5.22
    #define CvHASGV(cv) cBOOL(SvANY(cv)->xcv_gv_u.xcv_gv)
#endif


namespace xs {

using PerlTraceSP = iptr<PerlTrace>;

static string stringize_arg(SV* it) {
    string value;
    if (SvIS_FREED(it)) { value = "n/a"; }  // already freed
    else {
        Sv sv(it);
        bool escape = false;
        if      (!sv.defined())  { value += "undef"; }
        else if (sv.is_simple()) {
            Simple simple(sv);
            value = simple.as_string();
            escape = !simple.is_like_number();
        }
        else {
            char buff[32];
            auto res = to_chars(buff, buff+32, uint64_t(it), 16);
            if (!res.ec) {
                escape = true;
                auto size = res.ptr - buff;
                string addr = string("(0x") + string(buff, static_cast<size_t>(size)) + ")";

                string type = "UNKNOWN";
                if     (sv.is_io_ref())    { type = "IO"; }
                else if(sv.is_sub_ref())   { type = "CODE"; }
                else if(sv.is_array_ref()) { type = "ARRAY"; }
                else if(sv.is_hash_ref())  { type = "HASH"; }
                else if(sv.is_stash())     { type = "STASH"; }
                else if(sv.is_ref())       { type = "SCALAR"; }

                if(sv.is_object_ref()) {
                    addr = string("=") + type + addr;
                    Object obj(sv);
                    type = obj.stash().effective_name();
                }
                value = type + addr;
            }
            else { value = "*ERROR*"; }
        }
        value = (escape ? "'" : "") + value + (escape ? "'" : "");
    }
    return value;
}

static std::vector<string> get_args(const PERL_CONTEXT* cx) {
    std::vector<string> r;
    if (CxTYPE(cx) == CXt_SUB && CxHASARGS(cx)) {
        /* slot 0 of the pad contains the original @_ */
        AV * const ary = MUTABLE_AV(AvARRAY(MUTABLE_AV(PadlistARRAY(CvPADLIST(cx->blk_sub.cv))[cx->blk_sub.olddepth+1]))[0]);
        auto args_count = av_top_index(ary);
        //auto off = AvARRAY(ary) - AvALLOC(ary);
        auto off = 0;
        auto arr = AvARRAY(ary);
        auto last = args_count + off;
        for(decltype(off) i = off; i <= last; ++i) {
            auto it = arr[i];
            r.emplace_back(stringize_arg(it));
        }
    }
    return r;
}

static PerlTraceSP get_trace() noexcept {
    dTHX;
    std::vector<StackframeSP> frames;
    I32 level = 0;
    const PERL_CONTEXT *dbcx = nullptr;
    const PERL_CONTEXT* cx = caller_cx(level, &dbcx);
    while (cx) {
        if (!cx->blk_oldcop) break;
        auto pv_raw = CopSTASHPV(cx->blk_oldcop);
        auto file = CopFILE(cx->blk_oldcop);
        auto line = CopLINE(cx->blk_oldcop);

        xs::Sub sub;
        string name;
        string library;
        if ((CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT)) {
            if (CvHASGV(dbcx->blk_sub.cv)) {
                xs::Sub sub(dbcx->blk_sub.cv);
                name = sub.name();
                // just sub.stash().name() can't be called, as it omits
                // the effects of Sub::Name
                library = sub.glob().effective_stash().name();

            } else {
                name = "(unknown)";
            }
        } else {
            name = "(eval)";
        }

        if (!library && pv_raw) { library = pv_raw; };

        auto args = get_args(cx);

        StackframeSP frame(new Stackframe());
        frame->library = library;
        frame->file = file;
        frame->line_no = line;
        frame->name = name;
        frame->args = std::move(args);
        frames.emplace_back(std::move(frame));

        ++level;
        cx = caller_cx(level, &dbcx);
    }
    return new PerlTrace(std::move(frames));
}



Sv::payload_marker_t backtrace_c_marker{};
Sv::payload_marker_t backtrace_perl_marker{};

int payload_backtrace_c_free(pTHX_ SV*, MAGIC* mg) {
    if (mg->mg_virtual == &backtrace_c_marker) {
        auto* payload = static_cast<Backtrace*>((void*)mg->mg_ptr);
        delete payload;
    }
    return 0;
}

string _get_backtrace_string(Ref except, bool include_c_trace) {
    string result;
    auto it = except.value();
    if (include_c_trace) {
        string c_trace;
        if (it.payload_exists(&backtrace_c_marker)) {
            auto payload = it.payload(&backtrace_c_marker);
            auto bt = static_cast<Backtrace*>(payload.ptr);
            auto bt_info = bt->get_backtrace_info();
            if (bt_info) {
                c_trace += "C backtrace:\n";
                c_trace += bt_info->to_string();
            }
        }
        if (!c_trace) { result = "<C backtrace is n/a>\n"; }
        else          { result = c_trace;                  }
    }
    
    if (it.payload_exists(&backtrace_perl_marker)) {
        result += "Perl backtrace:\n";
        auto payload = it.payload(&backtrace_perl_marker);
        auto bt = xs::in<BacktraceInfo*>(payload.obj);
        for (const auto& frame : bt->get_frames() ) {
            result += frame->library + "::" + frame->name + " at " + frame->file + ":" + string::from_number(frame->line_no, 10) + "\n";
        }
    }
    else {
        result += "<Perl backtrace is n/a>";
    }
    return result;
}

string get_backtrace_string(Ref except) { return _get_backtrace_string(except, true); }
string get_backtrace_string_pp(Ref except) { return _get_backtrace_string(except, false); }

panda::iptr<DualTrace> get_backtrace(Ref except) {
    panda::iptr<DualTrace> r;
    auto it = except.value();
    if (it.payload_exists(&backtrace_perl_marker)) {
        r = new DualTrace();
        auto payload = it.payload(&backtrace_perl_marker);
        panda::BacktraceInfoSP bt(xs::in<BacktraceInfo*>(payload.obj));
        r->set_perl_trace([bt = bt]{ return bt; });
    }
    if (r && it.payload_exists(&backtrace_c_marker)) {
        auto payload = it.payload(&backtrace_c_marker);
        auto bt_ptr = static_cast<Backtrace*>(payload.ptr);
        r->set_c_trace([bt = *bt_ptr]{ return bt.get_backtrace_info(); });
    }
    return r;
}

panda::iptr<DualTrace> create_backtrace() {
    panda::iptr<DualTrace> r(new DualTrace());
    Backtrace c_bt;
    auto perl_bt = get_trace();
    r->set_c_trace([bt = c_bt]{ return bt.get_backtrace_info(); });
    r->set_perl_trace([perl_bt = perl_bt] { return perl_bt; });
    return r;
}

Ref _is_safe_to_wrap(Sv& ex, bool add_frame_info) {
    Ref ref;
    if (!ex.is_ref()) {
        /* try to mimic perl string error, i.e. "my-error at t/06-c-exceptions.t line 10."
         * we need that as when an exception is thrown from C-code, we wrap it into object
         * and frame info isn't addeded by Perl. 
         *
         * When an exception is thrown from Perl, Perl already added frame info. 
         */
        if (add_frame_info && ex.is_simple()) {

            auto str = Simple(ex).as_string();
            bool ends_with_newline = str.size() && str[str.size() - 1] == '\n';
            if (!ends_with_newline) {
                auto messed = Perl_mess_sv(aTHX_ ex, false);
                ref = Stash("Exception::Backtrace").call("new", Simple(messed));
            }
        }
        if (!ref) {
            ref = Stash("Exception::Backtrace").call("new", ex);
        }
    }
    else {  
        Ref tmp_ref(ex);
        auto it = tmp_ref.value();
        if (!(it.is_scalar() && it.readonly())) {
            ref = tmp_ref;
        }
    }
    return ref;

};

static bool has_backtraces(const Ref& except) {
    auto it = except.value();
    return it.payload_exists(&backtrace_c_marker) && it.payload_exists(&backtrace_perl_marker);
}

static void attach_backtraces(Ref except, const PerlTraceSP& perl_trace) {
    auto it = except.value();
    if (!it.payload_exists(&backtrace_c_marker)) {
        auto bt = new Backtrace();
        it.payload_attach(bt, &backtrace_c_marker);
    }
    if (!it.payload_exists(&backtrace_perl_marker)) {
        it.payload_attach(xs::out<BacktraceInfo*>(perl_trace.get()), &backtrace_perl_marker);
    }
}

Sv safe_wrap_exception(Sv ex) {
    auto ref = _is_safe_to_wrap(ex, false);
    if (ref) {
        if (has_backtraces(ref)) {
            return Sv(ref);
        }

        auto perl_traces = get_trace();
        auto& frames = perl_traces->get_frames();
        bool in_destroy = std::any_of(frames.begin(), frames.end(), [](auto& frame) { return frame->name == "DESTROY"; } );
        if (in_destroy) {
            // we don't want to corrupt Perl's warning with Exception::Backtrace handler, instead let it warns
            // to the origin of the exception
            return Simple::undef;
        }
        attach_backtraces(ref, perl_traces);
        return Sv(ref);
    }
    return Simple::undef;
}


void install_exception_processor() {
    add_exception_processor([](Sv& ex) -> Sv {
        auto ref = _is_safe_to_wrap(ex, true);
        if (ref) {
            auto it = ref.value();
            if (!it.payload_exists(&backtrace_c_marker)) {
                try { throw; }
                catch (const panda::Backtrace& err) {
                    // reuse existing c trace
                    it.payload_attach(new Backtrace(err), &backtrace_c_marker);
                }
                catch (...) {
                    // add new c trace
                    it.payload_attach(new Backtrace(), &backtrace_c_marker);
                }
            }
            if (!it.payload_exists(&backtrace_perl_marker)) {
                auto bt = get_trace();
                it.payload_attach(xs::out<BacktraceInfo*>(bt), &backtrace_perl_marker);
            }
            return Sv(ref);
        }
        return ex;
    });
}

panda::string as_perl_string(const panda::Stackframe& frame) {
    string r;
    r += frame.library;
    r += "::";
    r += frame.name;
    r += "(";
    auto& args = frame.args;
    auto last = args.size() - 1;
    for (size_t i = 0; i < args.size(); ++i) {
        r += args[i];
        if (i < last) { r += ", "; }
    }
    r += ")";
    r += " at ";
    r += frame.file;
    r += ":";
    r += string::from_number(frame.line_no, 10);
    return r;
}


}
