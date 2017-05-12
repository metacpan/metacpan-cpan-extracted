MODULE = LLVM				PACKAGE = LLVM::Const

Value
int(class, type, val)
	SV *class
	Type type
	unsigned long val

	CODE:
		RETVAL = LLVMConstInt(type, val, 0);

	OUTPUT: RETVAL

Value
real(class, type, val)
	SV *class
	Type type
	double val

	CODE:
		RETVAL = LLVMConstReal(type, val);

	OUTPUT: RETVAL

Value
string(class, val)
	SV *class
	SV *val

	CODE:
		STRLEN len;
		const char *str = SvPVbyte(val, len);

		RETVAL = LLVMConstString(str, len, 0);

	OUTPUT: RETVAL
