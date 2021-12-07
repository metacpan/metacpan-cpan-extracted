#include "PerlTraceInfo.h"
#include "backtrace.h"

using panda::string;

namespace xs {

string PerlFrame::to_string() const noexcept {
    return as_perl_string(*this);
}

string PerlTraceInfo::to_string() const noexcept {
    string r;
    for(size_t i = 0; i < frames.size(); ++i) {
        r += as_perl_string(*frames[i]);
        if (i + 1 < frames.size()) r += "\n";
    }
    return r;
}

std::vector<PerlFrameSP> PerlTraceInfo::get_frames() const noexcept {
    std::vector<PerlFrameSP> r;
    r.reserve(frames.size());
    for (auto& f: frames) {
        r.push_back(panda::static_pointer_cast<PerlFrame>(f));
    }
    return r;
}

}
