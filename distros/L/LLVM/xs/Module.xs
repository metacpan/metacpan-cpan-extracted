MODULE = LLVM				PACKAGE = LLVM::Module

Module
new(class, id)
	SV *class
	SV *id

	CODE:
		const char *name = SvPVbyte_nolen(id);

		RETVAL = LLVMModuleCreateWithName(name);

	OUTPUT: RETVAL

Value
add_func(self, func_name, func_type)
	Module self
	SV *func_name
	Type func_type

	CODE:
		const char *name = SvPVbyte_nolen(func_name);

		RETVAL = LLVMAddFunction(self, name, func_type);

	OUTPUT: RETVAL

Value
get_func(self, func_name)
	Module self
	SV *func_name

	CODE:
		const char *name = SvPVbyte_nolen(func_name);

		RETVAL = LLVMGetNamedFunction(self, name);

	OUTPUT: RETVAL

void
del_func(self, func)
	Module self
	Value func

	CODE:
		LLVMDeleteFunction(func);

Value
add_global(self, global_name, global_type)
	Module self
	SV *global_name
	Type global_type

	CODE:
		const char *name = SvPVbyte_nolen(global_name);

		RETVAL = LLVMAddGlobal(self, global_type, name);

	OUTPUT: RETVAL

Value
get_global(self, global_name)
	Module self
	SV *global_name

	CODE:
		const char *name = SvPVbyte_nolen(global_name);

		RETVAL = LLVMGetNamedGlobal(self, name);

	OUTPUT: RETVAL

void
del_global(self, global)
	Module self
	Value global

	CODE:
		LLVMDeleteGlobal(global);

void
dump(self)
	Module self

	CODE:
		LLVMDumpModule(self);

void
DESTROY(self)
	Module self

	CODE:
		LLVMDisposeModule(self);
