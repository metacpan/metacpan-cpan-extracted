#pragma once

#include "SharedObjectInfo.h"
#include <libdwarf/libdwarf.h>
#include <libdwarf/dwarf.h>
#include <memory>
#include <unordered_map>
#include <list>
#include <panda/exception.h>
#include <panda/optional.h>

namespace panda { namespace backtrace {

namespace dwarf {

struct HighLow {
    Dwarf_Addr high;
    Dwarf_Addr low;
};

enum class Match { yes, no, unknown };

struct FunctionDetails {
    panda::string name;
    std::uint64_t line_no = 0;
};

struct CUDetails {
    panda::string name;
};

struct DieHolder;
struct LookupResult;

struct DieRC: panda::Refcnt {
    Dwarf_Die die;
    Dwarf_Debug debug;
    panda::iptr<DieRC> parent;

    DieRC(Dwarf_Die die_, Dwarf_Debug debug_, panda::iptr<DieRC> parent_);
    ~DieRC();

    Dwarf_Die resolve_ref(Dwarf_Die source, Dwarf_Half attribute) noexcept;
    panda::iptr<DieRC> discover(Dwarf_Die target) noexcept;
    panda::iptr<DieRC> discover(Dwarf_Off target_offset, DieHolder& node) noexcept;
    string gather_fqn() noexcept;
    FunctionDetails refine_fn(LookupResult& lr) noexcept;
    void refine_fn_ao(Dwarf_Die abstract_origin, FunctionDetails& details) noexcept;
    void refine_fn_name(Dwarf_Die it, FunctionDetails& details) noexcept;
    void refine_fn_line(LookupResult& lr, FunctionDetails& details) noexcept;
    void refine_fn_line_fallback(Dwarf_Die it, FunctionDetails& details) noexcept;
    void refine_fn_spec(Dwarf_Die specification, FunctionDetails& details) noexcept;
    CUDetails refine_cu() noexcept;
};

struct DieHolder {
    Dwarf_Die die;
    Dwarf_Debug debug;
    DieHolder *parent;
    panda::iptr<DieRC> owner;

    DieHolder(panda::iptr<DieRC> owner);
    DieHolder(Dwarf_Die die_, Dwarf_Debug debug_, DieHolder* parent);
    DieHolder(const DieHolder&) = delete;
    DieHolder(DieHolder&&) = delete;

    panda::iptr<DieRC> detach();

    panda::optional<HighLow> get_addr() noexcept;
    Match contains(std::uint64_t offset) noexcept;
    ~DieHolder();
};

struct LookupResult {
    LookupResult() {}
    LookupResult(const LookupResult&) = delete;
    LookupResult(LookupResult&&);

    bool is_complete() noexcept;
    StackframePtr get_frame(std::uint64_t ip, const SharedObjectInfo& so) noexcept;

    panda::iptr<DieRC> cu;
    panda::iptr<DieRC> subprogram;
    std::uint64_t offset{0};
};

struct CU {
    Dwarf_Debug debug;
    int number;

    Dwarf_Unsigned header_length = 0;
    Dwarf_Unsigned abbrev_offset = 0;
    Dwarf_Half     address_size = 0;
    Dwarf_Half     version_stamp = 0;
    Dwarf_Half     offset_size = 0;
    Dwarf_Half     extension_size = 0;
    Dwarf_Unsigned typeoffset = 0;
    Dwarf_Half     header_type = DW_UT_compile;
    Dwarf_Sig8     signature;
    panda::iptr<DieRC> cu_die;
    CU(Dwarf_Debug debug, int number_);

    LookupResult resolve(std::uint64_t offset) noexcept;
    bool resolve(std::uint64_t offset, DieHolder& die, LookupResult& lr) noexcept;
    bool examine(std::uint64_t offset, DieHolder& die, LookupResult& lr) noexcept;
};
using CUPtr = std::unique_ptr<CU>;
}


struct DwarfInfo;

struct DwarfInfo {
    SharedObjectInfo so_info;
    Dwarf_Ptr err_arg = nullptr;
    Dwarf_Debug debug = nullptr;
    std::list<dwarf::CUPtr> CUs;

    DwarfInfo(const SharedObjectInfo& info_):so_info{info_}{}
    ~DwarfInfo();

    bool load() noexcept;
    StackframePtr resolve(std::uint64_t ip) noexcept;
};
using DwarfInfoMap = std::map<panda::string, std::unique_ptr<DwarfInfo>>;


void install_backtracer();

}}
