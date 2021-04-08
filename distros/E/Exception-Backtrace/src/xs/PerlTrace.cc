#include "PerlTrace.h"
#include "backtrace.h"

using panda::string;

namespace xs {

string PerlTrace::to_string() const noexcept {
    string r;
    for(size_t i = 0; i < frames.size(); ++i) {
        r += as_perl_string(*frames[i]);
        if (i + 1 < frames.size()) r += "\n";
    }
    return r;
}

}
