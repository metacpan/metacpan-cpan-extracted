#include "dwarf.h"
#include "glibc-dl.h"
#include "CTrace.h"
#include <limits.h>     // PATH_MAX
#include <libdwarf/dwarf.h>
#include <functional>
//#include <iostream> // for debug


namespace panda { namespace backtrace {

static iptr<BacktraceInfo> dl_produce(const RawTrace& buffer);
static BacktraceProducer dl_producer(dl_produce);

static DwarfInfoMap load_dwarf_info(const SharedObjectMap& so_map) {
    DwarfInfoMap result;
    for (auto& so: so_map) {
        auto info = std::make_unique<DwarfInfo>(so);
        char real_path[PATH_MAX] = {0};
        Dwarf_Error error;
        auto err = dwarf_init_path(so.name.c_str(), real_path, PATH_MAX, DW_DLC_READ, DW_GROUPNUMBER_ANY,
                                   nullptr, &info->err_arg, &info->debug, 0, 0, 0, &error);
        //std::cout << "loading " << so.name << ", code = " << err << "\n";
        if (err == DW_DLV_OK) {
            if (info->load()) {
                ///std::cout << "dwarf info initialized for " << so.name << "\n";
            }
        }
        // use DwarfInfoMap independently whether the real file was loaded. So, if file is not found
        // we still can produce stack frame with address/offset and .so name
        result.emplace(so.name, std::move(info));
    }
    return result;
}


iptr<BacktraceInfo> dl_produce(const RawTrace& buffer) {
    SharedObjectMap so_map;
    std::vector<StackframePtr> frames;
    gather_info(so_map);
    auto map = load_dwarf_info(so_map);
    for(void* ip_raw: buffer) {
        auto ip_addr = reinterpret_cast<std::uint64_t>(ip_raw);
        for(auto& it: map) {
            //std::cout << "resolving " << it.first << "\n";
            auto frame = it.second->resolve(ip_addr);
            if (frame) {
                frames.emplace_back(std::move(frame));
                break;
            }
        }
    }
    auto ptr = new CTrace(std::move(frames));
    return iptr<BacktraceInfo>(ptr);
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

bool DwarfInfo::load() noexcept {
    Dwarf_Error error;
    for(int cu_number = 0;;++cu_number) {
        auto cu = std::make_unique<dwarf::CU>(debug, cu_number);

        auto res = dwarf_next_cu_header_d(debug, true, &cu->header_length,
             &cu->version_stamp, &cu->abbrev_offset,
             &cu->address_size, &cu->offset_size,
             &cu->extension_size, &cu->signature,
             &cu->typeoffset, nullptr,
             &cu->header_type,&error);
        if (res != DW_DLV_OK) { break; }

        /* The CU will have a single sibling, a cu_die. */
        Dwarf_Die cu_die = nullptr;
        res = dwarf_siblingof_b(debug, nullptr, true,&cu_die, &error);
        if (res != DW_DLV_OK) { break; }

        dwarf::DieHolder cu_die_holder(cu_die, debug, nullptr);
        cu->cu_die = cu_die_holder.detach();
        CUs.emplace_back(std::move(cu));
    }
    return !CUs.empty();
}


StackframePtr DwarfInfo::resolve(std::uint64_t ip) noexcept {
    if (ip < so_info.begin || ip >= so_info.end) { return StackframePtr(); }

    auto offset = ip - so_info.begin;
    ///std::cout << "resolving " << std::hex << ip << "/" << offset << " from " <<  so_info.name <<  "\n";

    for(auto& cu: CUs) {
        auto r = cu->resolve(offset);
        if (r.is_complete()) { return r.get_frame(ip, so_info); }
    }

    // just fall-back to .so, address & offset
    auto frame = StackframePtr(new Stackframe());
    frame->library = so_info.name;
    frame->address = ip;
    frame->offset  = offset;
    return frame;
}

namespace dwarf {

LookupResult::LookupResult(LookupResult&& other) {
    cu = std::move(other.cu);
    subprogram = std::move(other.subprogram);
    offset = std::move(other.offset);
}
bool LookupResult::is_complete() noexcept { return cu && subprogram; }

StackframePtr LookupResult::get_frame(std::uint64_t ip, const SharedObjectInfo& so) noexcept {
    auto frame = StackframePtr(new Stackframe());
    //if (!is_complete()) { return frame; }

    //std::cout << "found die: " << (void*) die.die << ", h:" << addr->high << ", l: " << addr->low << ", o:" << offset << "\n";

    frame->address = ip;
    frame->offset = offset;
    frame->library = so.name;

    if (subprogram) {
        auto details = subprogram->refine_fn(*this);
        frame->name = details.name;
        frame->line_no = details.line_no;
    }

    if (cu) {
        auto details = cu->refine_cu();
        frame->file = details.name;
    }

    ///std::cout << frame->name << " at " << frame->file << ":" << frame->line_no << ", o:" << frame->offset << "\n";
    return frame;
}


DieRC::DieRC(Dwarf_Die die_, Dwarf_Debug debug_, panda::iptr<DieRC> parent_): die{die_}, debug{debug_}, parent{parent_} {}
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

panda::iptr<DieRC> DieRC::discover(Dwarf_Die target) noexcept {
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
    assert(0 && "should not happen");
}

panda::iptr<DieRC> DieRC::discover(Dwarf_Off target_offset, DieHolder& node) noexcept {
    Dwarf_Error error;
    Dwarf_Off off;
    int res;

    res = dwarf_dieoffset(node.die, &off, &error);
    assert(res == DW_DLV_OK);
    if (off == target_offset) { return node.detach(); }
    if (off > target_offset)  { return panda::iptr<DieRC>(); } /* do not lookup for fail branch */

    // in-breadth: check for siblings
    Dwarf_Die child_die;
    res = dwarf_siblingof_b(debug, node.die, true, &child_die, &error);
    if (res == DW_DLV_OK) {
        DieHolder child(child_die, debug, node.parent);
        auto found = discover(target_offset, child);
        if (found) { return found; }
    }

    // in-depth: check for child
    res = dwarf_child(node.die, &child_die, &error);
    if (res == DW_DLV_OK) {
        DieHolder child(child_die, debug, &node);
        auto found = discover(target_offset, child);
        if (found) { return found; }
    }

    return panda::iptr<DieRC>();
}


void DieRC::refine_fn_name(Dwarf_Die it, FunctionDetails& details) noexcept {
    if (!details.name) {
        Dwarf_Error error;
        Dwarf_Attribute attr_name;
        auto res = dwarf_attr(it, DW_AT_name, &attr_name, &error);
        if (res == DW_DLV_OK) {
            iptr<DieRC> node = (it == die) ? iptr<DieRC>(this) : discover(it);
            details.name = node->gather_fqn();
        }
    }
}

string DieRC::gather_fqn() noexcept {
    Dwarf_Error error;
    char* name = nullptr;
    auto res = dwarf_diename(die, &name, &error);
    assert(res == DW_DLV_OK);

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
            }
        }
        p = p->parent;
    }

    return r;
}

void DieRC::refine_fn_line(LookupResult& lr, FunctionDetails& details) noexcept {
    /* currently it detects lines only in the current CU (compilation unit */
    using LineContextHolder = std::unique_ptr<Dwarf_Line_Context, std::function<void(Dwarf_Line_Context *)>>;
    auto& cu = lr.cu;
    if (!cu) { return; }

    Dwarf_Error error;
    char* cu_name_raw;
    auto res = dwarf_die_text(cu->die, DW_AT_name, &cu_name_raw, &error);
    if (res != DW_DLV_OK) { return; }
    string cu_name(cu_name_raw);

    Dwarf_Unsigned line_version;
    Dwarf_Small table_type;
    Dwarf_Line_Context line_context;
    res = dwarf_srclines_b(cu->die, &line_version, &table_type,&line_context,&error);
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

        if (lineaddr >= lr.offset) { found = true; break;  }
        else                       { prev_lineno = lineno; }
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
            if (res == DW_DLV_OK) { details.line_no = line; }
        }
    }
}

FunctionDetails DieRC::refine_fn(LookupResult& lr) noexcept {
    FunctionDetails r;

    refine_fn_name(die, r);
    refine_fn_line(lr, r);
    refine_fn_line_fallback(die, r);

    if (!r.line_no || !r.name) {
        auto die_spec = resolve_ref(die, DW_AT_specification);
        if (die_spec) {
            refine_fn_spec(die_spec, r);
        }
    }

    if (!r.line_no || !r.name) {
        auto die_ao = resolve_ref(die, DW_AT_abstract_origin);
        if (die_ao) {
            refine_fn_ao(die_ao, r);
            if (die_ao) { refine_fn_ao(die_ao, r); }
        }
    }

    return r;
}

void DieRC::refine_fn_ao(Dwarf_Die abstract_origin, FunctionDetails& details) noexcept {
    auto die_spec = resolve_ref(abstract_origin, DW_AT_specification);
    if (die_spec) { refine_fn_spec(die_spec, details); }
}


void DieRC::refine_fn_spec(Dwarf_Die specification, FunctionDetails& details) noexcept {
    refine_fn_name(specification, details);
    refine_fn_line_fallback(specification, details);
}


CUDetails DieRC::refine_cu() noexcept {
    CUDetails r;
    Dwarf_Error error;
    char* name = nullptr;
    auto res = dwarf_die_text(die, DW_AT_name, &name, &error);
    if (res == DW_DLV_OK && name) { r.name = name; }
    return r;
}

DieHolder::DieHolder(panda::iptr<DieRC> owner_):die{owner_->die}, debug{owner_->debug}, parent{nullptr}, owner{owner_} {
    assert(!owner || owner->die);
}
DieHolder::DieHolder(Dwarf_Die die_, Dwarf_Debug debug_, DieHolder* parent_): die{die_}, debug{debug_}, parent{parent_}{
}

DieHolder::~DieHolder() {
    if (!owner) { dwarf_dealloc(debug, die,DW_DLA_DIE); }
}

panda::iptr<DieRC> DieHolder::detach(){
    if (!owner) {
        panda::iptr<DieRC> parent_ptr(parent ? parent->detach() : nullptr);
        owner = panda::iptr<DieRC>(new DieRC(die, debug, parent_ptr));
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
    memset(&signature,0, sizeof(signature));
}

LookupResult CU::resolve(std::uint64_t offset) noexcept {
    assert(cu_die);
    LookupResult lr;
    DieHolder dh(cu_die);
    resolve(offset, dh, lr);
    return lr;
}

bool CU::resolve(std::uint64_t offset, DieHolder& die, LookupResult& lr) noexcept {
    //std::cout << "resolving die: " << (void*) die.die << "\n";

    auto er = examine(offset, die, lr);
    if (er || lr.is_complete()) { return er; }

    Dwarf_Die child_die = nullptr;
    Dwarf_Error error;
    int res;

    // in-breadth: check for siblings
    res = dwarf_siblingof_b(debug, die.die, true, &child_die, &error);
    if (res == DW_DLV_OK) {
        DieHolder child(child_die, debug, die.parent);
        resolve(offset, child, lr);
        if (lr.is_complete()) { return true; }
    } else if (res == DW_DLV_NO_ENTRY) {
        /* ignore */
    } else {
        return true;
    }

    // in-depth: check for child
    res = dwarf_child(die.die, &child_die, &error);
    if(res == DW_DLV_OK) {
        DieHolder child(child_die, debug, &die);
        resolve(offset, child, lr);
        if (lr.is_complete()) { return true; }
    } else if (res == DW_DLV_NO_ENTRY) {
        /* ignore */
        return true;
    } else {
        return true;
    }

    return true;
}

bool CU::examine(std::uint64_t offset, DieHolder &die, LookupResult& lr) noexcept {
    Dwarf_Error error;
    Dwarf_Half tag = 0;
    assert(die.die);
    auto res = dwarf_tag(die.die, &tag, &error);
    if (res != DW_DLV_OK) { return true; }

    if( tag == DW_TAG_subprogram ||
        tag == DW_TAG_inlined_subroutine) {
        switch (die.contains(offset)) {
        case Match::yes: {
            lr.subprogram = die.detach();
            lr.offset = offset;
            return lr.is_complete();
        }
        case Match::unknown: return false;
        case Match::no:      return false;
        }
    }
    else if(tag == DW_TAG_compile_unit) {
        switch (die.contains(offset)) {
        case Match::yes: {
            lr.cu = die.detach();
            return lr.is_complete();
        }
        case Match::unknown: return false;
        case Match::no:      return true;
        }
    }

    /* keep scaning */
    return false;
}

}}}
