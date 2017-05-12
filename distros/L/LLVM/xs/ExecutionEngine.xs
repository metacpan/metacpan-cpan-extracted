MODULE = LLVM				PACKAGE = LLVM::ExecutionEngine

ExecutionEngine
new(class, mod)
	SV *class
	Module mod

	CODE:
		char *err;
		ExecutionEngine engine;

		if (LLVMCreateExecutionEngineForModule(&engine, mod, &err)) {
			Perl_croak(aTHX_ "%s", err);
		}

		RETVAL = engine;

	OUTPUT: RETVAL

GenericValue
run_func(self, func, ...)
	ExecutionEngine self
	Value func

	CODE:
		int i;

		GenericValue *params = malloc(
			sizeof(GenericValue) * (items - 2)
		);

		for (i = 2; i < items; i++) {
			GenericValue param;
			SV *arg = ST(i);

			if (sv_isobject(arg) &&
				   sv_derived_from(arg, "LLVM::GenericValue"))
				param = INT2PTR(GenericValue, SvIV((SV *) SvRV(arg)));
			else
				Perl_croak(aTHX_
					"arg is not of type LLVM::GenericValue");

			params[i - 2] = param;
		}

		RETVAL = LLVMRunFunction(self, func, (items - 2), params);

	OUTPUT: RETVAL
