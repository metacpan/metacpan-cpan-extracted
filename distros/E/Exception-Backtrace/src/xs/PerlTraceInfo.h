#pragma once

#include <panda/exception.h>
#include <panda/refcnt.h>
#include <vector>
#include <xs.h>

namespace xs {

struct PerlFrame : panda::Stackframe {
    using panda::Stackframe::Stackframe;
    panda::string to_string() const noexcept;
};

using PerlFrameSP = panda::iptr<PerlFrame>;



struct PerlTraceInfo: panda::BacktraceInfo {
    using panda::BacktraceInfo::BacktraceInfo;
    virtual panda::string to_string() const noexcept override;

    std::vector<PerlFrameSP> get_frames() const noexcept;
};

using PerlTraceInfoSP = panda::iptr<PerlTraceInfo>;

}
