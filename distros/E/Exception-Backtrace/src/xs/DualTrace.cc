#include "DualTrace.h"

using panda::string;

namespace xs {

string DualTrace::to_string() noexcept {
    string r;
    if (c_trace) {
        r += "C backtrace:\n";
        r += c_trace->to_string();
    }
    if (perl_trace) {
        r += "Perl backtrace:\n";
        r += perl_trace->to_string();
    }
    return r;
}

}
