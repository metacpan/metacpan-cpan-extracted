MODULE = LLVM				PACKAGE = LLVM::GenericValue

GenericValue
int(class, type, val)
	SV *class
	Type type
	unsigned long val

	CODE:
		RETVAL = LLVMCreateGenericValueOfInt(type, val, 1);
	OUTPUT: RETVAL

GenericValue
uint(class, type, val)
	SV *class
	Type type
	unsigned long val

	CODE:
		RETVAL = LLVMCreateGenericValueOfInt(type, val, 0);
	OUTPUT: RETVAL

GenericValue
float(class, type, val)
	SV *class
	Type type
	double val

	CODE:
		RETVAL = LLVMCreateGenericValueOfFloat(type, val);
	OUTPUT: RETVAL

unsigned long
to_int(self)
	GenericValue self

	CODE:
		RETVAL = LLVMGenericValueToInt(self, 1);
	OUTPUT: RETVAL

unsigned long
to_uint(self)
	GenericValue self

	CODE:
		RETVAL = LLVMGenericValueToInt(self, 0);
	OUTPUT: RETVAL

double
to_float(self, type)
	GenericValue self
	Type type

	CODE:
		RETVAL = LLVMGenericValueToFloat(type, self);
	OUTPUT: RETVAL

void
DESTROY(self)
	GenericValue self

	CODE:
		LLVMDisposeGenericValue(self);
