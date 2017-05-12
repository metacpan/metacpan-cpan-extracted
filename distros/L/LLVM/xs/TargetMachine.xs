MODULE = LLVM				PACKAGE = LLVM::TargetMachine

TargetMachine
create(class, target, triple, cpu, features)
	SV *class
	Target target
	SV *triple
	SV *cpu
	AV *features

	CODE:
		int i, count = av_len(features) + 1;
		char **features_str = malloc(sizeof(char *) * count);

		for (i = 0; i < count; i++) {
			SV *cur = av_shift(features);
			const char *f = SvPVbyte_nolen(cur);

			features_str[i] = f;
		}

		RETVAL = LLVMCreateTargetMachine(
			target,
			SvPVbyte_nolen(triple),
			SvPVbyte_nolen(cpu),
			*features_str,
			LLVMCodeGenLevelDefault,
			LLVMRelocDefault,
			LLVMCodeModelDefault
		);

	OUTPUT: RETVAL

void
emit(self, mod, file, to_object)
	TargetMachine self
	Module mod
	SV *file
	bool to_object

	CODE:
		char *err;

		bool rc = LLVMTargetMachineEmitToFile(
			self, mod, SvPVbyte_nolen(file),
			(to_object ? LLVMObjectFile : LLVMAssemblyFile), &err
		);

		if (rc) Perl_croak(aTHX_ "%s", err);

void
DESTROY(self)
	TargetMachine self

	CODE:
		LLVMDisposeTargetMachine(self);
