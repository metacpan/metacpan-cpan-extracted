#include <xs.h>
#include "src/xs/backtrace.h"
#include <panda/backtrace.h>

using namespace xs;
using namespace panda;

MODULE = Exception::Backtrace                PACKAGE = Exception::Backtrace
PROTOTYPES: DISABLE

BOOT {
    backtrace_c_marker.svt_free = &xs::payload_backtrace_c_free;
    install_exception_processor();  // XS::Framework

    panda::backtrace::install();
    xs::at_perl_destroy([]{
        panda::backtrace::uninstall();
     });
}

panda::string get_backtrace_string(Ref except) {
    RETVAL = get_backtrace_string(except);
}

panda::string get_backtrace_string_pp(Ref except) {
    RETVAL = get_backtrace_string_pp(except);
}

iptr<DualTrace> get_backtrace(Ref except) {
    RETVAL = get_backtrace(except);
}

iptr<DualTrace> create_backtrace() {
    RETVAL = create_backtrace();
}

Sv safe_wrap_exception(Sv ex) { RETVAL = safe_wrap_exception(ex); }

INCLUDE: xs/DualTrace.xsi

INCLUDE: xs/BacktraceInfo.xsi

INCLUDE: xs/Stackframe.xsi
