#include <xs.h>
#include "src/xs/backtrace.h"

using namespace xs;
using namespace panda::backtrace;
using namespace panda;

MODULE = Exception::Backtrace                PACKAGE = Exception::Backtrace
PROTOTYPES: DISABLE

BOOT {
    backtrace_c_marker.svt_free = &xs::payload_backtrace_c_free;
    install_exception_processor();  // XS::Framework
    install_backtracer();           // XS::libpanda
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

INCLUDE: DualTrace.xsi

INCLUDE: BacktraceInfo.xsi

INCLUDE: Stackframe.xsi
