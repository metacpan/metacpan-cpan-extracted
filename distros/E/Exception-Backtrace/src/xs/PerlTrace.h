#pragma once

#include <panda/exception.h>
#include <panda/refcnt.h>
#include <vector>

namespace xs {

struct PerlTrace: panda::BacktraceInfo {
    using panda::BacktraceInfo::BacktraceInfo;
    virtual panda::string to_string() const noexcept override;
};

}
