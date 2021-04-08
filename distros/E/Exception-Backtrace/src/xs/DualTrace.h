#pragma once

#include <panda/exception.h>
#include <panda/refcnt.h>
#include <panda/function.h>
#include <functional>

namespace xs {

struct DualTrace: public panda::Refcnt {
    using BacktraceInfoFn = panda::function<panda::BacktraceInfoSP>;

    DualTrace() noexcept {};

    panda::BacktraceInfoSP get_c_trace() noexcept;
    panda::BacktraceInfoSP get_perl_trace() noexcept;

    void set_c_trace(BacktraceInfoFn&& producer) noexcept { c_trace_producer = std::move(producer); }
    void set_perl_trace(BacktraceInfoFn&& producer) noexcept { perl_trace_producer = std::move(producer); }

    panda::string to_string() noexcept;

private:

    panda::BacktraceInfoSP c_trace_cached;
    BacktraceInfoFn c_trace_producer;

    panda::BacktraceInfoSP perl_trace_cached;
    BacktraceInfoFn perl_trace_producer;
};

}
