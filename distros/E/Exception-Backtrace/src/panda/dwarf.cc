#include "dwarf.h"
#include "dl.h"
#include <limits.h>     // PATH_MAX
#include <libdwarf/dwarf.h>
#include <functional>
#include <memory>
#include <iostream> // for debug
#include <cstring>


#include <stdio.h>

#ifdef _WIN32
#include <windows.h>
#define PANDA_PATH_MAX MAX_PATH
#else
#define PANDA_PATH_MAX PATH_MAX
#endif

namespace panda { namespace backtrace {

static BacktraceBackendSP dl_produce(const Backtrace& raw_traces);
static BacktraceProducer dl_producer(dl_produce);

static DwarfInfoMap load_dwarf_info(const SharedObjectMap& so_map) {
    DwarfInfoMap result;
    for (auto& so: so_map) {
        auto info = std::make_unique<DwarfInfo>(so);
        string real_path(PANDA_PATH_MAX);
        Dwarf_Error error;

        FILE* file;
        file = fopen(so.name.c_str(), "rb");
        DwarfInfo::file_guard_t file_guard (file, [](auto* f){ if (f) {fclose(f); }});
        int fd = file ? fileno(file) : 0;
        if (fd > 0) {
            auto err = dwarf_init_b(fd, DW_DLC_READ, DW_GROUPNUMBER_ANY, nullptr, &info->err_arg, &info->debug, &error);
            //std::cout << "loading '" << so.name << "', code = " << err << "\n";
            if (err == DW_DLV_OK) {
                if (info->load(std::move(file_guard))) {
                    //std::cout << "dwarf info initialized for " << so.name << "\n";
                }
            } else if (err == DW_DLV_ERROR) {
                //std::cout << "error initializing on " << so.name << " :: " << dwarf_errmsg(error) << "\n";
            }
            // use DwarfInfoMap independently whether the real file was loaded. So, if file is not found
            // we still can produce stack frame with address/offset and .so name
        }
        result.emplace(so.name, std::move(info));
    }
    return result;
}

struct DwarfBackend: BacktraceBackend {
    const Backtrace& raw_traces;
    DwarfInfoMap info_map;

    DwarfBackend(const Backtrace& raw_traces_) noexcept: raw_traces{raw_traces_} {
        SharedObjectMap so_map;
        gather_info(so_map);
        info_map = load_dwarf_info(so_map);
    }

    bool produce_frame(StackFrames& frames, size_t i) override {
        auto frame_ptr = raw_traces.buffer.at(i);
        auto ip_addr = reinterpret_cast<std::uint64_t>(frame_ptr);
        for(auto& it: info_map) {
            //std::cout << "resolving " << it.first << "\n";
            if (it.second->resolve(ip_addr, frames)) return true;
        }
        return false;
    }

};

BacktraceBackendSP dl_produce(const Backtrace& raw_traces) {
    return new DwarfBackend(raw_traces);
}

void install_backtracer() {
    panda::Backtrace::install_producer(dl_producer);
}


DwarfInfo::~DwarfInfo() {
    if (debug) {
        CUs.clear(); // DIEs must be released before debug
        Dwarf_Error error;
        auto res = dwarf_finish(debug, &error);
        if (res != DW_DLV_OK) {
             fprintf(stderr, "dwarf_finish: %s\n", dwarf_errmsg(error));
        }
    }
}

bool DwarfInfo::load(file_guard_t&& guard_) noexcept {
    guard = std::move(guard_);
    Dwarf_Error error;
    for(int cu_number = 0;;++cu_number) {
        auto cu = dwarf::CUSP(new dwarf::CU(debug, cu_number));

        auto res = dwarf_next_cu_header_d(debug, true, &cu->header_length,
             &cu->version_stamp, &cu->abbrev_offset,
             &cu->address_size, &cu->offset_size,
             &cu->extension_size, &cu->signature,
             &cu->typeoffset, nullptr,
             &cu->header_type,&error);
        if (res != DW_DLV_OK) { break; }

        /* The CU will have a single sibling, a cu_die. */
        Dwarf_Die cu_die = nullptr;
        res = dwarf_siblingof_b(debug, nullptr, true, &cu_die, &error);
        if (res != DW_DLV_OK) { break; }

        dwarf::DieHolder cu_die_holder(cu_die, debug, nullptr);
        cu->cu_die = cu_die_holder.detach();
        CUs.emplace_back(std::move(cu));
    }
    return !CUs.empty();
}


bool DwarfInfo::resolve(std::uint64_t ip, StackFrames &frames) noexcept {
    if (ip < so_info.begin || ip >= so_info.end) { return false; }

    auto offset = so_info.get_offset(ip);
    /// std::cout << "resolving " << std::hex << ip << "/" << offset << " from " <<  so_info.name << ", CUs: " << CUs.size() << "\n";

    for(auto it = CUs.begin(); it != CUs.end(); ++it){
        //if (r.is_complete()) std::cout << "hit\n";
        auto& cu = *it;
        auto r = cu->resolve(offset);
        if (r.is_complete()) { return r.get_frames(ip, so_info, frames); }
    }

    // just fall-back to .so, address & offset
    auto frame = StackframeSP(new Stackframe());
    frame->library = so_info.name;
    frame->address = ip;
    frame->offset  = offset;
    frames.emplace_back(std::move(frame));
    return true;
}

namespace dwarf {

LookupResult::LookupResult(LookupResult&& other) {
    cu = std::move(other.cu);
    root = std::move(other.root);
    subprogram = std::move(other.subprogram);
    offset = std::move(other.offset);
}
bool LookupResult::is_complete() noexcept { return cu && subprogram; }

bool LookupResult::get_frames(std::uint64_t ip, const SharedObjectInfo& so, StackFrames &frames) noexcept {
    //if (!is_complete()) { return frame; }

    auto push_frame = [&](const auto& details) {
        auto frame = StackframeSP(new Stackframe());
        frame->address = ip;
        frame->offset = offset;
        frame->library = so.name;

        if (details.name)    frame->name    = details.name;
        if (details.line_no) frame->line_no = details.line_no;
        if (details.source)  frame->file    = details.source;

        frames.emplace_back(std::move(frame));
    };

    if (subprogram) {
        auto location =  subprogram->refine_location(offset);
        auto details = location->refine_fn(*this);
        push_frame(details);

        // printf("refined: %s at %lu, offset: %lu(%lx)\n", details.name.c_str(), details.line_no, offset, offset);
        while(!location->context.empty()) {
            auto outer = location->context.back();
            location->context.pop_back();
            auto details = outer->refine_fn(*this);
            push_frame(details);
            //printf("refined (outer): %s at %u\n", details.name.c_str(), details.line_no);
        }
    } else {
        push_frame(FunctionDetails());
    }

    ///std::cout << frame->name << " at " << frame->file << ":" << frame->line_no << ", o:" << frame->offset << "\n";
    return true;
}


DieRC::DieRC(Dwarf_Die die_, Dwarf_Debug debug_, DieSP parent_): die{die_}, debug{debug_}, parent{parent_} {}
DieRC::~DieRC() {
    dwarf_dealloc(debug, die,DW_DLA_DIE);
}

Dwarf_Die DieRC::resolve_ref(Dwarf_Die source, Dwarf_Half attr) noexcept {
    Dwarf_Die r = nullptr;
    Dwarf_Attribute attr_val;
    Dwarf_Error error;
    auto res = dwarf_attr(source, attr, &attr_val, &error);
    if (res == DW_DLV_OK) {
        Dwarf_Off attr_offset = 0;
        res = dwarf_global_formref(attr_val,&attr_offset,&error);
        if (res == DW_DLV_OK) {
            res = dwarf_offdie_b(debug, attr_offset, true, &r, &error);
            if (res == DW_DLV_OK) { return r; }
        }
    }
    return nullptr;
}

DieSP DieRC::discover(Dwarf_Die target) noexcept {
    auto p = parent;
    while (p->parent) { p = p->parent; }

    DieHolder root(p);
    /* no need to scan CU-siblings */
    Dwarf_Die child_die = nullptr;
    Dwarf_Error error;
    auto res = dwarf_child(p->die, &child_die, &error);


    if(res == DW_DLV_OK) {
        DieHolder child(child_die, debug, &root);
        Dwarf_Off off;
        res = dwarf_dieoffset(target, &off, &error);
        assert(res == DW_DLV_OK);
        return discover(off, child);
    }

    std::abort();
}

template<typename CheckFN>
DieSP traverse_sibling_or_child(DieHolder& node, CheckFN&& fn){
    Dwarf_Error error;
    Dwarf_Die child_die;
    int res = dwarf_siblingof_b(node.debug, node.die, true, &child_die, &error);
    if (res == DW_DLV_OK) {
        DieHolder child(child_die, node.debug, node.parent);
        auto found = fn(child);
        if (found) { return found; }
    }

    // in-depth: check for child
    res = dwarf_child(node.die, &child_die, &error);
    if (res == DW_DLV_OK) {
        DieHolder child(child_die, node.debug, &node);
        auto found = fn(child);
        if (found) { return found; }
    }
    return DieSP();
}

DieSP DieRC::discover(Dwarf_Off target_offset, DieHolder& node) noexcept {
    Dwarf_Error error;
    Dwarf_Off off;
    int res;

    res = dwarf_dieoffset(node.die, &off, &error);
    assert(res == DW_DLV_OK);
    if (off == target_offset) { return node.detach(); }
    if (off > target_offset)  { return DieSP(); } /* do not lookup for fail branch */

    return traverse_sibling_or_child(node, [&](DieHolder& child){ return discover(target_offset, child);  });
}


void DieRC::refine_fn_name(Dwarf_Die it, FunctionDetails& details) noexcept {
    if (!details.name) {
        Dwarf_Error error;
        Dwarf_Attribute attr_name;
        auto res = dwarf_attr(it, DW_AT_name, &attr_name, &error);

        if (res == DW_DLV_OK) {
            iptr<DieRC> node = (it == die) ? iptr<DieRC>(this) : discover(it);
            auto fqn = node->gather_fqn();
            details.name = fqn.full_name;
            details.name_die = fqn.source_die;
            return;
        }

        auto die_spec = resolve_ref(it, DW_AT_specification);
        if (die_spec) return refine_fn_spec(die_spec, details);

        auto die_ao = resolve_ref(it, DW_AT_abstract_origin);
        if (die_ao) return refine_fn_name(die_ao, details);
    }
}

DieRC::FQN DieRC::gather_fqn() noexcept {
    Dwarf_Error error;
    DieSP source_die;

    auto try_record_source = [&](DieSP it) mutable {
        Dwarf_Bool has_source;
        if (!source_die) {
            int res = dwarf_hasattr(it->die, DW_AT_decl_file, &has_source, &error);
            if (res == DW_DLV_OK && has_source) {
                source_die = it;
            }
        }
    };


    char* name = nullptr;
    auto res = dwarf_diename(die, &name, &error);
    assert(res == DW_DLV_OK);
    try_record_source(DieSP(this));

    string r(name);

    auto p = parent;
    while(p) {
        Dwarf_Half tag = 0;
        res = dwarf_tag(p->die, &tag, &error);
        assert(res == DW_DLV_OK);
        if (tag == DW_TAG_structure_type || tag == DW_TAG_class_type || tag == DW_TAG_namespace) {
            Dwarf_Attribute attr_name;
            res = dwarf_attr(p->die, DW_AT_name, &attr_name, &error);
            if (res == DW_DLV_OK) {
                char* prefix;
                dwarf_formstring(attr_name, &prefix, &error);
                assert(res == DW_DLV_OK);
                r = string(prefix) + "::" + r;
                try_record_source(p);
            }
        }
        p = p->parent;
    }

    return FQN{r, source_die};
}

void DieRC::refine_fn_line(Dwarf_Die die, std::uint64_t offset, FunctionDetails& details) noexcept {
    /* currently it detects lines only in the current CU (compilation unit) */
    using LineContextHolder = std::unique_ptr<Dwarf_Line_Context, std::function<void(Dwarf_Line_Context *)>>;

    Dwarf_Error error;
    char* cu_name_raw;
    auto res = dwarf_die_text(die, DW_AT_name, &cu_name_raw, &error);
    if (res != DW_DLV_OK) { return; }
    string cu_name(cu_name_raw);

    Dwarf_Unsigned line_version;
    Dwarf_Small table_type;
    Dwarf_Line_Context line_context;
    res = dwarf_srclines_b(die, &line_version, &table_type,&line_context,&error);
    if (res != DW_DLV_OK) { return; }
    LineContextHolder line_context_guard(&line_context, [](auto it){ dwarf_srclines_dealloc_b(*it); });

    Dwarf_Signed base_index, end_index, cu_index = -1;
    Dwarf_Signed file_count;
    res = dwarf_srclines_files_indexes(line_context, &base_index,&file_count,&end_index, &error);
    if (res != DW_DLV_OK) { return; }

    //std::cout << "looking indices for " << cu_name << ", b = " << base_index << ", e = " << end_index << "\n";

    for (Dwarf_Signed i = base_index; i < end_index; ++i) {
        Dwarf_Unsigned modtime;
        Dwarf_Unsigned flength;
        Dwarf_Unsigned dirindex;
        const char *source_name;

        res = dwarf_srclines_files_data(line_context, i, &source_name ,&dirindex, &modtime, &flength, &error);
        if (res != DW_DLV_OK) { return; }
        if (cu_name.find(source_name) != string::npos) {
            if (dirindex) {
                const char* dir_name;
                res = dwarf_srclines_include_dir_data(line_context, static_cast<Dwarf_Signed>(dirindex), &dir_name, &error);
                if (res != DW_DLV_OK) { return; }

                if (cu_name.find(dir_name) != string::npos) {
                    cu_index = i;
                    break;
                }
            } else {
                /* no directory / current directory */
                cu_index = i;
                break;
            }
        }
    }
    if (cu_index == -1) { return; }

    Dwarf_Line *linebuf;
    Dwarf_Signed linecount;
    res = dwarf_srclines_from_linecontext(line_context, &linebuf, &linecount, &error);
    if (res != DW_DLV_OK) { return; }


    bool found = false;
    Dwarf_Unsigned prev_lineno = 0;
    for(Dwarf_Signed i = 0; i < linecount; ++i) {
        Dwarf_Unsigned lineno = 0;
        Dwarf_Unsigned file_index = 0;
        Dwarf_Addr lineaddr = 0;

        res = dwarf_lineno(linebuf[i], &lineno, &error);
        if (res != DW_DLV_OK) { return; }
        res = dwarf_lineaddr(linebuf[i], &lineaddr, &error);
        if (res != DW_DLV_OK) { return; }
        res = dwarf_line_srcfileno(linebuf[i],&file_index, &error);
        if (res != DW_DLV_OK) { return; }
        if (file_index != static_cast<Dwarf_Unsigned>(cu_index)) { continue; }

        if (lineaddr >=  offset) { found = true; break;  }
        else                     { prev_lineno = lineno; }
    }

    if (found) {
        details.line_no = prev_lineno;
    }
    //std::cout << "refine_fn_line  " << found << " :: " << lr.offset << " :: " << std::dec << prev_lineno << "\n";
}


void DieRC::refine_fn_line_fallback(Dwarf_Die it, FunctionDetails& details) noexcept {
    if (!details.line_no) {
        Dwarf_Error error;

        Dwarf_Attribute attr_line;
        auto res = dwarf_attr(it, DW_AT_decl_line, &attr_line, &error);
        if (res == DW_DLV_OK) {
            Dwarf_Unsigned line;
            res = dwarf_formudata(attr_line, &line, &error);
            if (res == DW_DLV_OK) { details.line_no = line + 1; }
        }
    }
}

FunctionDetails DieRC::refine_fn(LookupResult& lr) noexcept {
    FunctionDetails r;

    refine_fn_name(die, r);
    refine_fn_line(lr.cu->die, lr.offset, r);
    if (!r.line_no && r.name_die) refine_fn_line_fallback(r.name_die->die, r);

    if (r.name_die) refine_fn_source(r.name_die->die, r, *lr.root);
    //printf("n = %s\n", r.name ? r.name.c_str() : "n/a");

    return r;
}

void DieRC::refine_fn_source(Dwarf_Die it, FunctionDetails& details, CU& cu) noexcept {
    if (!details.source) {
        Dwarf_Error error;
        Dwarf_Attribute attr_file;
        auto res = dwarf_attr(it, DW_AT_decl_file, &attr_file, &error);
        if (res == DW_DLV_OK) {
            Dwarf_Unsigned file_index;
            res = dwarf_formudata(attr_file, &file_index, &error);
            if (res == DW_DLV_OK && file_index) {
                details.source = cu.get_source(file_index);
            }
        }
    }
}


void DieRC::refine_fn_ao(Dwarf_Die abstract_origin, FunctionDetails& details) noexcept {
    refine_fn_name(abstract_origin, details);
    if (!details.name) {
        auto die_spec = resolve_ref(abstract_origin, DW_AT_specification);
        if (die_spec) { refine_fn_spec(die_spec, details); }
    }
}


void DieRC::refine_fn_spec(Dwarf_Die specification, FunctionDetails& details) noexcept {
    refine_fn_name(specification, details);
    refine_fn_line_fallback(specification, details);
}

template<typename CheckFN>
Scan traverse(DieHolder& die, CheckFN&& fn) noexcept {
    //std::cout << "resolving die: " << (void*) die.die << "\n";

    auto er = fn(die);
    if (er == Scan::found) return er;

    Dwarf_Die child_die = nullptr;
    Dwarf_Error error;
    int res;

    // in-breadth: check for siblings
    res = dwarf_siblingof_b(die.debug, die.die, true, &child_die, &error);
    if (res == DW_DLV_OK) {
        DieHolder child(child_die, die.debug, die.parent);
        auto sr = traverse(child, fn);
        if (sr == Scan::found) return sr;
    } else if (res == DW_DLV_NO_ENTRY) {
        /* ignore */
    } else {
        return Scan::dead_end;
    }

    // in-depth: check for child
    if (er != Scan::dead_end) {
        res = dwarf_child(die.die, &child_die, &error);
        if(res == DW_DLV_OK) {
            DieHolder child(child_die, die.debug, &die);
            auto sr = traverse(child, fn);
            if (sr == Scan::found) return sr;
        }
    }

    return Scan::dead_end;
}

DieSP DieRC::refine_location(uint64_t offset) noexcept {
    DieCollection context{{DieSP(this)}};
    DieHolder root(context.front());

    Dwarf_Die child_die = nullptr;
    Dwarf_Error error;
    int res = dwarf_child(die, &child_die, &error);
    if (res == DW_DLV_OK) {
        DieHolder child(child_die, debug, &root);
        traverse(child, [&](DieHolder& node) mutable {
            Dwarf_Error error;
            Dwarf_Half tag = 0;

            res = dwarf_tag(node.die, &tag, &error);
            if (res != DW_DLV_OK) { return Scan::dead_end; }

            if( tag == DW_TAG_subprogram ||
                tag == DW_TAG_inlined_subroutine) {
                switch(node.contains(offset)) {
                    case Match::no:  return Scan::dead_end;
                    case Match::yes: context.push_back(node.detach()); break;
                    default: break;
                }
            }
            /* scan everything */
            return Scan::not_found;
        });
    }

    auto best = context.back();
    context.pop_back();
    best->context = std::move(context);
    return best;
}

DieHolder::DieHolder(DieSP owner_):die{owner_->die}, debug{owner_->debug}, parent{nullptr}, owner{owner_} {
    assert(!owner || owner->die);
}
DieHolder::DieHolder(Dwarf_Die die_, Dwarf_Debug debug_, DieHolder* parent_): die{die_}, debug{debug_}, parent{parent_}{
}

DieHolder::~DieHolder() {
    if (!owner) { dwarf_dealloc(debug, die,DW_DLA_DIE); }
}

DieSP DieHolder::detach(){
    if (!owner) {
        DieSP parent_ptr(parent ? parent->detach() : nullptr);
        owner = DieSP(new DieRC(die, debug, parent_ptr));
    }
    return owner;
}

panda::optional<HighLow> DieHolder::get_addr() noexcept {
    Dwarf_Error error;
    Dwarf_Addr low = 0;
    Dwarf_Addr high = 0;

    auto res = dwarf_lowpc(die,&low,&error);
    if (res == DW_DLV_OK) {
        Dwarf_Form_Class formclass;
        Dwarf_Half form = 0;
        res = dwarf_highpc_b(die,&high,&form,&formclass,&error);
        if (res == DW_DLV_OK) {
            if (formclass == DW_FORM_CLASS_CONSTANT) { high += low; }
            return panda::optional<HighLow>{HighLow{low, high}};
        }
    }
    /*  Cannot check ranges yet, we don't know the ranges base offset yet. */
    return panda::optional<HighLow>();
}

Match DieHolder::contains(std::uint64_t offset) noexcept {
    auto addr = get_addr();
    if (addr) {
        if ((addr->high >= offset) || (addr->low < offset)) {
            return Match::no;
        } else {
            return Match::yes;
        }
    } else {
        Dwarf_Error error;
        Dwarf_Attribute attr;
        auto res = dwarf_attr(die, DW_AT_ranges, &attr, &error);
        if (res == DW_DLV_OK) {
            Dwarf_Off ranges_offset;
            res = dwarf_global_formref(attr, &ranges_offset, &error);
            if (res == DW_DLV_OK) {
                Dwarf_Ranges *ranges;
                Dwarf_Signed  ranges_count;
                Dwarf_Unsigned  byte_count;
                res = dwarf_get_ranges_a(debug, ranges_offset, die, &ranges, &ranges_count, &byte_count, &error);
                if (res == DW_DLV_OK) {
                    Dwarf_Addr baseaddr = 0;
                    for(int i = 0; i < ranges_count; ++i) {
                        auto r = ranges[i];
                        switch (r.dwr_type) {
                        case DW_RANGES_ADDRESS_SELECTION: baseaddr = r.dwr_addr2; break;
                        case DW_RANGES_ENTRY: {
                            auto low = r.dwr_addr1 + baseaddr;
                            auto high = r.dwr_addr2 + baseaddr;
                            auto matches = (low <= offset) && (high > offset);
                            //std::cout << "l = " << low << ", h = " << high << ", attr = " << ranges_offset << ", o = " << offset << " " << (matches ? "Y" : "N") << "\n";
                            if (matches) {return Match::yes; }
                            break;
                        }
                        default: break;

                        }
                    }
                    if (ranges_count > 0) { return Match::no; }
                }
            }
        }
    }
    return Match::unknown;
}



CU::CU(Dwarf_Debug debug_, int number_): debug{debug_}, number{number_} {
    std::memset(&signature, 0, sizeof(signature));
}

CU::~CU() {
    if (sources) {
        for(size_t i = 0; i < static_cast<size_t>(sources_count); ++i) {
             dwarf_dealloc(debug, sources[i], DW_DLA_STRING);
        }
        dwarf_dealloc(debug, sources, DW_DLA_LIST);
    }
}

LookupResult CU::resolve(std::uint64_t offset) noexcept {
    assert(cu_die);
    LookupResult lr(*this);
    DieHolder dh(cu_die);
    resolve(offset, dh, lr);
    return lr;
}

Scan CU::resolve(std::uint64_t offset, DieHolder& die, LookupResult& lr) noexcept {
    return traverse(die, [&](DieHolder& node){ return examine(offset, node, lr); });
}

Scan CU::examine(std::uint64_t offset, DieHolder &die, LookupResult& lr) noexcept {
    Dwarf_Error error;
    Dwarf_Half tag = 0;
    assert(die.die);
    auto res = dwarf_tag(die.die, &tag, &error);
    if (res != DW_DLV_OK) { return Scan::dead_end; }

    if( tag == DW_TAG_subprogram ||
        tag == DW_TAG_inlined_subroutine) {
        switch (die.contains(offset)) {
        case Match::yes: {
            lr.subprogram = die.detach();
            lr.offset = offset;
            return Scan::found;
        }
        default: return Scan::not_found;
        }
    }
    else if(tag == DW_TAG_compile_unit) {
        switch (die.contains(offset)) {
        case Match::yes: {
            lr.cu = die.detach();
            return lr.is_complete() ? Scan::found : Scan::not_found;
        }
        case Match::unknown: return Scan::not_found;
        case Match::no:      return Scan::dead_end;
        }
    }

    /* keep scaning */
    return Scan::not_found;
}

string CU::get_source(size_t index) noexcept {
    if (!sources_count) {
        auto res = dwarf_srcfiles(cu_die->die, &sources, &sources_count, nullptr);
        if (res != DW_DLV_OK) { sources_count = -1; }
    }
    if (sources_count > 0 && index < static_cast<size_t>(sources_count)) {
        /* "subtract 1 to index into srcfiles", see dwarf_line.c */
        return string(sources[index - 1]);
    }
    return string{};
}


}}}
