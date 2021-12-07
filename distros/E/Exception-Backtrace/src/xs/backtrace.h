#pragma once

#include <xs/Ref.h>
#include <panda/exception.h>
#include <xs/typemap.h>
#include <xs/function.h>

#include "DualTrace.h"
#include "PerlTraceInfo.h"

namespace xs {

struct PerlArgumentsHolder: panda::ArgumentsHolder {
    xs::Simple args;
};

extern Sv::payload_marker_t backtrace_c_marker;
extern Sv::payload_marker_t backtrace_perl_marker;

int payload_backtrace_c_free(pTHX_ SV*, MAGIC* mg);

panda::string get_backtrace_string(Ref except);
panda::string get_backtrace_string_pp(Ref except);
panda::iptr<DualTrace> get_backtrace(Ref except);
panda::iptr<DualTrace> create_backtrace();
panda::string as_perl_string(const panda::Stackframe& frame);

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

template <class TYPE>
struct Typemap<PerlTraceInfo*, TYPE*>: Typemap<panda::BacktraceInfo*, TYPE*> {
    static panda::string_view package() {return "Exception::Backtrace::PerlTraceInfo"; }
};

template <class TYPE>
struct Typemap<panda::Stackframe*, TYPE*>: TypemapObject<panda::Stackframe*, TYPE*, ObjectTypeRefcntPtr, ObjectStorageMG>{
    static panda::string_view package() {return "Exception::Backtrace::Stackframe"; }
};

template <class TYPE>
struct Typemap<PerlFrame*, TYPE*>: Typemap<panda::Stackframe*, TYPE*> {
    static panda::string_view package() {return "Exception::Backtrace::PerlFrame"; }
};

template <> struct Typemap<panda::ArgumentsHolder*> : TypemapBase<panda::ArgumentsHolder*> {
    static Sv out (panda::ArgumentsHolder* var, const Sv& = {}) {
        return static_cast<PerlArgumentsHolder*>(var)->args;
    }
};



};
