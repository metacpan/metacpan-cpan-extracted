#pragma once

#include <xs/Ref.h>
#include <panda/exception.h>
#include <xs/typemap.h>
#include "DualTrace.h"

namespace xs {

extern Sv::payload_marker_t backtrace_c_marker;
extern Sv::payload_marker_t backtrace_perl_marker;

int payload_backtrace_c_free(pTHX_ SV*, MAGIC* mg);

panda::string get_backtrace_string(Ref except);
panda::string get_backtrace_string_pp(Ref except);
panda::iptr<DualTrace> get_backtrace(Ref except);
panda::iptr<DualTrace> create_backtrace();

Sv safe_wrap_exception(Sv ex);
void install_exception_processor();


template <>
struct Typemap<DualTrace*>: TypemapObject<DualTrace*, DualTrace*, ObjectTypeRefcntPtr, ObjectStorageMG>{
    static panda::string_view package() {return "Exception::Backtrace::DualTrace"; }
};

template <class TYPE>
struct Typemap<panda::BacktraceInfo*, TYPE*>: TypemapObject<panda::BacktraceInfo*, TYPE*, ObjectTypeRefcntPtr, ObjectStorageMG>{
    static panda::string_view package() {return "Exception::Backtrace::BacktraceInfo"; }
};

template <>
struct Typemap<panda::Stackframe*>: TypemapObject<panda::Stackframe*, panda::Stackframe*, ObjectTypeRefcntPtr, ObjectStorageMG>{
    static panda::string_view package() {return "Exception::Backtrace::Stackframe"; }
};

};
