#pragma once

#include <panda/exception.h>
#include <panda/refcnt.h>

namespace xs {

struct DualTrace: public panda::Refcnt {
    panda::iptr<panda::BacktraceInfo> c_trace;
    panda::iptr<panda::BacktraceInfo> perl_trace;

    panda::string to_string() noexcept;
};

}
