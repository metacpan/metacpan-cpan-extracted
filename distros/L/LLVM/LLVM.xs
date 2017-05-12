#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <llvm-c/Core.h>

#include <llvm-c/Transforms/IPO.h>
#include <llvm-c/Transforms/Scalar.h>
#include <llvm-c/Transforms/Vectorize.h>

typedef LLVMModuleRef		Module;
typedef LLVMTypeRef		Type;
typedef LLVMValueRef		Value;
typedef LLVMBasicBlockRef	BasicBlock;
typedef LLVMBuilderRef		Builder;
typedef LLVMPassManagerRef	PassManager;

#include <llvm-c/ExecutionEngine.h>

typedef LLVMGenericValueRef	GenericValue;
typedef LLVMExecutionEngineRef	ExecutionEngine;

#include <llvm-c/TargetMachine.h>

typedef LLVMTargetRef		Target;
typedef LLVMTargetMachineRef	TargetMachine;

MODULE = LLVM				PACKAGE = LLVM

# Core
INCLUDE: xs/Module.xs
INCLUDE: xs/Type.xs
INCLUDE: xs/Value.xs
INCLUDE: xs/Const.xs
INCLUDE: xs/Builder.xs
INCLUDE: xs/PassManager.xs

# ExecutionEngine
INCLUDE: xs/GenericValue.xs
INCLUDE: xs/ExecutionEngine.xs

# TargetMachine
INCLUDE: xs/Target.xs
INCLUDE: xs/TargetMachine.xs
