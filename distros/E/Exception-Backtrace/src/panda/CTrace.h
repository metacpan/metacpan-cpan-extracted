#pragma once

#include <panda/exception.h>
#include <panda/refcnt.h>
#include <vector>

namespace panda { namespace backtrace {

struct CTrace: panda::BacktraceInfo {
    CTrace(std::vector<panda::StackframePtr>&& frames_):frames{std::move(frames_)}{}
    virtual panda::string to_string() const override;
    virtual const std::vector<panda::StackframePtr>& get_frames() const override { return frames; }

    std::vector<panda::StackframePtr> frames;
};


}}

