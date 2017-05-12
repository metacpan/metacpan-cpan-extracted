#if defined(SWIGCSHARP) || defined (SWIGPHP) || defined (SWIGOCTAVE) || defined (SWIGOCAML)
%module(directors="1") KappaCUDA
#else
#if defined(SWIGJAVA)
%module(directors="1") KappaCUDAjava
#else
%module KappaCUDA
#endif
#endif

%include "std_string.i"

#if defined (SWIGRUBY)
%rename (CudaGPU) cudaGPU;
%include "cpointer.i"
%pointer_class (bool, IOCancel);
#if !defined (SWIGPHP) && !defined (SWIGOCTAVE)
%include "carrays.i"
%array_class(int, IntArray);
%array_class(long, LongArray);
%array_class(unsigned, UnsignedArray);
%array_class(float, FloatArray);
%array_class(double, DoubleArray);
#endif
#else
%include "cpointer.i"
%pointer_class (bool, IOCancel);
#if !defined (SWIGPHP) && !defined (SWIGOCTAVE)
%include "carrays.i"
%array_class(int, intArray);
%array_class(long, longArray);
%array_class(unsigned, unsignedArray);
%array_class(float, floatArray);
%array_class(double, doubleArray);
#endif
#endif

%pointer_cast (void *, int *, PVoidToPInt);
%pointer_cast (void *, unsigned *, PVoidToPUnsigned);
%pointer_cast (void *, long *, PVoidToPLong);
%pointer_cast (void *, float *, PVoidToPFloat);
%pointer_cast (void *, double *, PVoidToPDouble);

#define USE_OPENGL 1

#ifdef SWIGPERL
%perlcode %{
$KappaCUDA::VERSION = '1.5.0';
%}
#endif

#ifdef SWIGPYTHON
%ignore None;
#endif

#ifdef SWIGRUBY
// These give compile errors
%ignore kappa::Arguments::Type;
%ignore kappa::Value::Type;
#endif

#if defined(SWIGCSHARP) || defined(SWIGJAVA) || defined (SWIGPHP) || defined (SWIGOCTAVE) || defined (SWIGOCAML)
// This gives a compile warning.
%ignore kappa::Command::GetType;
#if !defined(SWIGJAVA)
%feature ("director") kappa::ExceptionHandler;
#endif
%feature ("director") kappa::command::Keyword;
%feature ("director") kappa::Recipient;
%feature ("director") kappa::IOCallback;
#endif

%ignore kappa::Context::GetStream(const char*);
%ignore kappa::Context::Copy(const char*,const char*);
%ignore kappa::Context::ModuleVariable;
%ignore kappa::Context::FreeVariable(const char*);
%ignore kappa::Context::GetVariable(const char*);
%ignore kappa::Context::GetArray(const char*);
%ignore kappa::Command::Command(const char*);
%ignore kappa::Command::SetName(const char*);

//---------------------------------------------------
// The next section is for ignoring overloaded methods for
// types that do not differentiate for the the given language(s).
//---------------------------------------------------
#if defined (SWIGPHP) || defined (SWIGOCAML)
%ignore kappa::Values::Add(std::string,bool);
%ignore kappa::Value::Set(bool);
%ignore kappa::Attributes::Get(std::string,bool);
%ignore kappa::Arguments::Add(bool);
%ignore kappa::Arguments::In(bool);
%ignore kappa::Arguments::Get(unsigned int,bool);
#endif
#if defined(SWIGLUA) || defined (SWIGPHP) || defined (SWIGPIKE) || defined (SWIGCHICKEN) || defined (SWIGGUILE) || defined (SWIGMZSCHEME) || defined (SWIGOCAML)
%ignore kappa::Values::Add(std::string,float);
%ignore kappa::Value::Set(float);
%ignore kappa::Attributes::Get(std::string,float);
%ignore kappa::Arguments::Add(float);
%ignore kappa::Arguments::In(float);
%ignore kappa::Arguments::Get(unsigned int,float);
%ignore kappa::Variable::DeviceMemSet(unsigned char,unsigned int);
#endif

#if defined (SWIGPIKE) || defined (SWIGCHICKEN) || defined (SWIGOCAML)
%ignore kappa::Context::NewLocalAndDevice(char const *,unsigned int,bool);
%ignore kappa::Context::NewLocalAndDevice(char const *,unsigned int,unsigned int,bool);
%ignore kappa::Context::NewLocalAndDevice(char const *,unsigned int,unsigned int,unsigned int,bool);
#endif

#if defined (SWIGALLEGROCL) || defined (SWIGOCAML)
%ignore kappa::Variable::DeviceMemSet(unsigned char,unsigned int);
#endif
#if defined(SWIGLUA) || defined (SWIGR) || defined (SWIGALLEGROCL) || defined (SWIGPIKE) || defined (SWIGCHICKEN) || defined (SWIGGUILE) || defined (SWIGMZSCHEME) || defined (SWIGOCAML)
%ignore kappa::Variable::DeviceMemSet(unsigned short,unsigned int);
#endif
//---------------------------------------------------


// The Kappa constructor should not be used.
%ignore kappa::Kappa::Kappa;
// The Kappa::Instance methods using c/c++ argc/argv are not useful to scripting languages.
%ignore kappa::Kappa::Instance (const int,const char **,const unsigned int,LOCK_TYPE);
%ignore kappa::Kappa::Instance (const int,const char **,const unsigned int);
%ignore kappa::Kappa::Instance (const int,const char **);
// Use the new Kappa::Instance std::string methods.
%ignore kappa::Kappa::Instance (const char *,const char *,const unsigned int,LOCK_TYPE);
%ignore kappa::Kappa::Instance (const char *,const char *,const unsigned int);
%ignore kappa::Kappa::Instance (const char *,const char *);

// Ignore non-exported (hidden) methods and variables
%ignore kappa::Kappa::Cancel;
%ignore kappa::Kappa::End;
%ignore kappa::Kappa::Done;
%ignore kappa::Kappa::CPUProcess;
%ignore kappa::Kappa::GPUProcess;
%ignore cuDevice;
%ignore kappa_version;
%ignore kappa::Process::Process;
%ignore kappa::Process::GetIOCallbackFunction;
%ignore kappa::Resource::Resource;
%ignore kappa::Resource::CommandDone;
%ignore kappa::Resource::CheckCommandReady;
%ignore kappa::Context::Context;
#if !defined(SWIGCSHARP) && !defined(SWIGJAVA)
%ignore kappa::Recipient;
#endif
%ignore kappa::Variable::Variable;
%ignore kappa::Array::Array;
%ignore kappa::DeviceMemory;
%ignore kappa::DeviceTexture;
%ignore kappa::LocalMemory;
#if defined(SWIGCSHARP) || defined (SWIGJAVA) || defined (SWIGPHP) || defined (SWIGOCTAVE) || defined (SWIGOCAML)
%ignore RegisterIOCallback (std::string, IOCallbackFunction *, void *);
#endif

#if defined (SWIGOCTAVE)
%ignore kappa::Context::SetPrintfFIFOSize;
#endif

// ignored because of: 'not supported' 'no type checking rule'
#if defined (SWIGOCAML)
%ignore kappa::ExceptionHandler::Catch;
%ignore kappa::IOCallback::IOMethod;
%ignore kappa::Values::Add(std::string,kappa::Value *);
%ignore kappa::Values::Add(std::string,uint16_t);
%ignore kappa::Values::Add(std::string,uint32_t);
%ignore kappa::Values::Add(std::string,uint64_t);
%ignore kappa::Values::Add(std::string,double);
%ignore kappa::Values::Add(std::string,void *);
%ignore kappa::Values::Add(std::string,std::string);
%ignore kappa::Values::Add(std::string,Indices *);
%ignore kappa::Values::Add(std::string,uint8_t);
%ignore kappa::Value::Set(uint8_t);
%ignore kappa::Value::Set(uint16_t);
%ignore kappa::Value::Set(int16_t);
%ignore kappa::Value::Set(uint32_t);
%ignore kappa::Value::Set(int32_t);
%ignore kappa::Value::Set(uint64_t);
%ignore kappa::Value::Set(int64_t);
%ignore kappa::Value::Set(std::string);
%ignore kappa::Value::Set(int8_t);
%ignore kappa::Value::Set(std::string,value::TYPE);
%ignore kappa::Value::Get(value::type::Byte);
%ignore kappa::Value::Get(value::type::Byte2);
%ignore kappa::Value::Get(value::type::SByte2);
%ignore kappa::Value::Get(value::type::Byte4);
%ignore kappa::Value::Get(value::type::SByte4);
%ignore kappa::Value::Get(value::type::Byte8);
%ignore kappa::Value::Get(value::type::SByte8);
%ignore kappa::Value::Get(value::type::Bool);
%ignore kappa::Value::Get(value::type::Float);
%ignore kappa::Value::Get(value::type::Double);
%ignore kappa::Value::Get(value::type::Indices);
%ignore kappa::Value::Get(value::type::Void_Ptr);
%ignore kappa::Value::Get(value::type::String);
%ignore kappa::Value::Get(value::type::Variable);
%ignore kappa::Value::Get(value::type::Expression);
%ignore kappa::Value::Get(value::type::Config_Value);
%ignore kappa::Value::Get(value::type::Namespace_Value);
%ignore kappa::Value::Get(value::type::Singlequoted_String);
%ignore kappa::Value::Get(value::type::Unidentified_String);
%ignore kappa::Value::Get(value::type::SByte);
%ignore kappa::Instruction::Instruction;
%ignore kappa::Attributes::Get(std::string,uint8_t);
%ignore kappa::Attributes::Get(std::string,uint32_t);
%ignore kappa::Attributes::Get(std::string,uint64_t);
%ignore kappa::Attributes::Get(std::string,double);
%ignore kappa::Attributes::Get(std::string,void *);
%ignore kappa::Attributes::Get(std::string,std::string);
%ignore kappa::Attributes::Get(std::string,Indices *);
%ignore kappa::Attributes::Get(std::string,uint16_t);
%ignore kappa::Arguments::Add(uint8_t);
%ignore kappa::Arguments::Add(uint16_t);
%ignore kappa::Arguments::Add(uint32_t);
%ignore kappa::Arguments::Add(uint64_t);
%ignore kappa::Arguments::Add(std::string);
%ignore kappa::Arguments::TexRef(std::string);
%ignore kappa::Arguments::Out(std::string);
%ignore kappa::Arguments::IO(std::string);
%ignore kappa::Arguments::In(uint8_t);
%ignore kappa::Arguments::In(uint16_t);
%ignore kappa::Arguments::In(uint32_t);
%ignore kappa::Arguments::In(uint64_t);
%ignore kappa::Arguments::In(std::string);
%ignore kappa::Arguments::Get(unsigned int,uint8_t);
%ignore kappa::Arguments::Get(unsigned int,uint32_t);
%ignore kappa::Arguments::Get(unsigned int,uint64_t);
%ignore kappa::Arguments::Get(unsigned int,std::string);
%ignore kappa::Arguments::Get(unsigned int,uint16_t);
%ignore kappa::Context::New(char const *,Indices,unsigned int);
%ignore kappa::Context::NewLocalAndDevice(char const *,Indices,unsigned int);
%ignore kappa::Context::NewLocalAndDevice(char const *,Indices,unsigned int,bool);
%ignore kappa::Context::NewLocalOnly(char const *,Indices,unsigned int);
%ignore kappa::Context::NewDevice(char const *,Indices,unsigned int);
%ignore kappa::Context::NewDeviceOnly(char const *,Indices,unsigned int);
%ignore kappa::Context::ModuleVariable;
#endif

#pragma SWIG nowarn=319,401,402
#if defined (SWIGPHP)
#pragma SWIG nowarn=314
#endif

#if defined (SWIGPERL)
%begin %{
#include <string>
#ifdef _WIN32
#include <msxml.h>
#endif
%}
#endif

%{
// Undefine Perl's NORMAL--it just causes problems
#undef NORMAL
#include "kappa/Lock.h"
#include "Kappa.h"
#include "KappaConfig.h"
#if !defined(SWIGOCAML)
#include "kappa/ArgumentsDirection.h"
#endif
#include "kappa/ExceptionHandler.h"
#include "kappa/cudaGPU.h"
#if defined(SWIGCSHARP) || defined(SWIGJAVA) || defined (SWIGPHP) || defined (SWIGOCTAVE) || defined (SWIGOCAML)
#include "kappa/IOCallback.h"
#endif
#if defined(SWIGCSHARP) || defined(SWIGJAVA) || defined (SWIGPHP) || defined (SWIGOCTAVE) || defined (SWIGOCAML)
#include "kappa/Commands/Keyword.h"
#include "kappa/Recipient.h"
#endif
#include "kappa/Process.h"
#include "kappa/Result.h"
#include "kappa/Namespace.h"
#include "kappa/Values.h"
#include "kappa/Value.h"
#include "kappa/Resource.h"
#include "kappa/Instruction.h"
#include "kappa/Attributes.h"
#include "kappa/Arguments.h"
#include "kappa/ProcessControlBlock.h"
// Undefine Perl's Copy and New macros--they just causes problems
#undef Copy
#undef New
#undef IsSet
#include "kappa/ContextType.h"
#include "kappa/Context.h"
#include "kappa/Command.h"
#include "kappa/Variable.h"
#include "kappa/Array.h"

KAPPA_DLL_EXPORT int *intptr_fromvoidptr(void *voidptr);
KAPPA_DLL_EXPORT unsigned *unsignedptr_fromvoidptr(void *voidptr);
KAPPA_DLL_EXPORT long *longptr_fromvoidptr(void *voidptr);
KAPPA_DLL_EXPORT float *floatptr_fromvoidptr(void *voidptr);
KAPPA_DLL_EXPORT double *doubleptr_fromvoidptr(void *voidptr);

using namespace kappa;
%}

#define __attribute__(A)
%include "kappa/Common.h"
%include "kappa/Lock.h"
%include "Kappa.h"
%include "KappaConfig.h"
#if !defined(SWIGOCAML)
%include "kappa/ArgumentsDirection.h"
#endif
%include "kappa/ExceptionHandler.h"
%include "kappa/cudaGPU.h"
#if defined(SWIGCSHARP) || defined(SWIGJAVA) || defined (SWIGPHP) || defined (SWIGOCTAVE) || defined (SWIGOCAML)
%include "kappa/IOCallback.h"
#endif
%include "kappa/Process.h"
%include "kappa/Result.h"
%include "kappa/Namespace.h"
%include "kappa/Values.h"
%include "kappa/Value.h"
%include "kappa/Resource.h"
%include "kappa/Instruction.h"
%include "kappa/Attributes.h"
%include "kappa/Arguments.h"
%include "kappa/ProcessControlBlock.h"
%include "kappa/ContextType.h"
%include "kappa/Context.h"
%include "kappa/Command.h"
%include "kappa/Variable.h"
%include "kappa/Array.h"

KAPPA_DLL_EXPORT int *intptr_fromvoidptr(void *voidptr);
KAPPA_DLL_EXPORT unsigned *unsignedptr_fromvoidptr(void *voidptr);
KAPPA_DLL_EXPORT long *longptr_fromvoidptr(void *voidptr);
KAPPA_DLL_EXPORT float *floatptr_fromvoidptr(void *voidptr);
KAPPA_DLL_EXPORT double *doubleptr_fromvoidptr(void *voidptr);

%{
KAPPA_DLL_EXPORT int *intptr_fromvoidptr(void *voidptr) {
    return (int *)voidptr;
}

KAPPA_DLL_EXPORT unsigned *unsignedptr_fromvoidptr(void *voidptr) {
    return (unsigned *)voidptr;
}

KAPPA_DLL_EXPORT long *longptr_fromvoidptr(void *voidptr) {
    return (long *)voidptr;
}

KAPPA_DLL_EXPORT float *floatptr_fromvoidptr(void *voidptr) {
    return (float *)voidptr;
}

KAPPA_DLL_EXPORT double *doubleptr_fromvoidptr(void *voidptr) {
    return (double *)voidptr;
}
%}

#ifdef SWIGPYTHON
KAPPA_DLL_EXPORT kappa::Command *kappaCommand_frompycobject(PyObject *voidptr);
KAPPA_DLL_EXPORT kappa::Kappa *kappaKappa_frompycobject(PyObject *voidptr);
KAPPA_DLL_EXPORT kappa::Process *kappaProcess_frompycobject(PyObject *voidptr);
KAPPA_DLL_EXPORT kappa::Attributes *kappaAttributes_frompycobject(PyObject *voidptr);
KAPPA_DLL_EXPORT kappa::Arguments *kappaArguments_frompycobject(PyObject *voidptr);
KAPPA_DLL_EXPORT kappa::Resource *kappaResource_frompycobject(PyObject *voidptr);
KAPPA_DLL_EXPORT kappa::ProcessControlBlock *kappaPCB_frompycobject(PyObject *voidptr);

%{
KAPPA_DLL_EXPORT kappa::Command *kappaCommand_frompycobject(PyObject *pycptr) {
  return (kappa::Command *)PyCObject_AsVoidPtr (pycptr);
}
KAPPA_DLL_EXPORT kappa::Kappa *kappaKappa_frompycobject(PyObject *pycptr) {
  return (kappa::Kappa *)PyCObject_AsVoidPtr (pycptr);
}
KAPPA_DLL_EXPORT kappa::Process *kappaProcess_frompycobject(PyObject *pycptr) {
  return (kappa::Process *)PyCObject_AsVoidPtr (pycptr);
}
KAPPA_DLL_EXPORT kappa::Attributes *kappaAttributes_frompycobject(PyObject *pycptr) {
  return (kappa::Attributes *)PyCObject_AsVoidPtr (pycptr);
}
KAPPA_DLL_EXPORT kappa::Arguments *kappaArguments_frompycobject(PyObject *pycptr) {
  return (kappa::Arguments *)PyCObject_AsVoidPtr (pycptr);
}
KAPPA_DLL_EXPORT kappa::Resource *kappaResource_frompycobject(PyObject *pycptr) {
  return (kappa::Resource *)PyCObject_AsVoidPtr (pycptr);
}
KAPPA_DLL_EXPORT kappa::ProcessControlBlock *kappaPCB_frompycobject(PyObject *pycptr) {
  return (kappa::ProcessControlBlock *)PyCObject_AsVoidPtr (pycptr);
}
%}
#endif
