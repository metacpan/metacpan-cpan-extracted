#pragma once

#include <vector>
#include <cstdint>
#include <panda/string.h>


namespace panda { namespace backtrace {

struct SharedObjectInfo {
    std::uint64_t begin;
    std::uint64_t end;
    string name;

    SharedObjectInfo(std::uint64_t begin_, std::uint64_t end_, string name_):begin{begin_}, end{end_}, name{name_}{}
    SharedObjectInfo(const SharedObjectInfo&) = default;
    SharedObjectInfo(SharedObjectInfo&&) = default;
};

using SharedObjectMap = std::vector<SharedObjectInfo>;

}}
