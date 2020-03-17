#include <xs.h>
#include <panda/exception.h>

using namespace xs;

MODULE = MyTest                PACKAGE = MyTest
PROTOTYPES: DISABLE

void call(Sub cb) {
    cb();
}

void throw_logic_error() {
    throw std::logic_error("my-logic-error");
}

void throw_backtrace() {
    throw panda::exception("my-error");
}

void throw_with_newline() {
    throw std::logic_error("my-error\n");
}
