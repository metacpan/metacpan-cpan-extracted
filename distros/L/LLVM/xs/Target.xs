MODULE = LLVM				PACKAGE = LLVM::Target

AV *
targets(class)
	SV *class

	CODE:
		Target t; SV *curr;
		AV *targets = newAV();

		LLVMInitializeAllTargets();
		LLVMInitializeAllTargetInfos();
		LLVMInitializeAllTargetMCs();
		LLVMInitializeAllAsmPrinters();

		t = LLVMGetFirstTarget();

		do {
			curr = sv_setref_pv(
				newSV(0), "LLVM::Target", (void *) t
			);

			av_push(targets, curr);

			t = LLVMGetNextTarget(t);
		} while (t);

		RETVAL = targets;

	OUTPUT: RETVAL

SV *
name(self)
	Target self

	CODE:
		const char *name = LLVMGetTargetName(self);
		RETVAL = newSVpv(name, 0);

	OUTPUT: RETVAL

SV *
description(self)
	Target self

	CODE:
		const char *name = LLVMGetTargetDescription(self);
		RETVAL = newSVpv(name, 0);

	OUTPUT: RETVAL
