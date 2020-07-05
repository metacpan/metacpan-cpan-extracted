#include <xs.h>
#include <panda/exception.h>

using namespace xs;
using namespace panda;


template<typename> static inline void fn_1() {
    throw panda::exception("my-error");
}

template<typename> static inline void fn_2() {
    fn_1<std::uint16_t>();
}

MODULE = MyTest                PACKAGE = MyTest
PROTOTYPES: DISABLE

size_t default_trace_depth() {
    RETVAL = Backtrace().get_backtrace_info()->frames.size();
}

void call(Sub cb) {
    cb();
}

void throw_logic_error() {
    throw std::logic_error("my-logic-error");
}

void throw_backtrace() {
    auto fn = []() { fn_2<std::string>(); };
    fn();
}

void throw_with_newline() {
    throw std::logic_error("my-error\n");
}
