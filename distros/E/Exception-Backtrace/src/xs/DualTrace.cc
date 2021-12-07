#include "DualTrace.h"

using panda::string;

namespace xs {

panda::BacktraceInfoSP DualTrace::get_c_trace() noexcept {
    if (!c_trace_cached && c_trace_producer) {
        c_trace_cached = c_trace_producer();
    }
    return c_trace_cached;
}

PerlTraceInfoSP DualTrace::get_perl_trace() noexcept {
    if (!perl_trace_cached && perl_trace_producer) {
        perl_trace_cached = panda::static_pointer_cast<PerlTraceInfo>(perl_trace_producer());
    }
    return perl_trace_cached;
}

string DualTrace::to_string() noexcept {
    string r;
    auto c_trace = get_c_trace();
    if (c_trace) {
        r += "C backtrace:\n";
        r += c_trace->to_string();
    }

    auto perl_trace = get_perl_trace();
    if (perl_trace) {
        r += "Perl backtrace:\n";
        r += perl_trace->to_string();
    }
    return r;
}

}
