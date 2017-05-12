MODULE = LLVM				PACKAGE = LLVM::PassManager

PassManager
new(class)
	SV *class

	CODE:
		RETVAL = LLVMCreatePassManager();

	OUTPUT: RETVAL

bool
run(self, mod)
	PassManager self
	Module mod

	CODE:
		RETVAL = LLVMRunPassManager(self, mod);

	OUTPUT: RETVAL

void add(self, pass, ...)
	PassManager self
	SV *pass

	CODE:
		char *spass = SvPVbyte_nolen(pass);

		# FIXME: find a less ugly way of doing this

		# IPO transformations
		if (strcmp(spass, "ArgumentPromotion") == 0)
			LLVMAddArgumentPromotionPass(self);
		else if (strcmp(spass, "ConstantMerge") == 0)
			LLVMAddConstantMergePass(self);
		else if (strcmp(spass, "DeadArgElimination") == 0)
			LLVMAddDeadArgEliminationPass(self);
		else if (strcmp(spass, "FunctionAttrs") == 0)
			LLVMAddFunctionAttrsPass(self);
		else if (strcmp(spass, "FunctionInlining") == 0)
			LLVMAddFunctionInliningPass(self);
		else if (strcmp(spass, "AlwaysInliner") == 0)
			LLVMAddAlwaysInlinerPass(self);
		else if (strcmp(spass, "GlobalDCE") == 0)
			LLVMAddGlobalDCEPass(self);
		else if (strcmp(spass, "GlobalOptimizer") == 0)
			LLVMAddGlobalOptimizerPass(self);
		else if (strcmp(spass, "IPConstantPropagation") == 0)
			LLVMAddIPConstantPropagationPass(self);
		else if (strcmp(spass, "PruneEH") == 0)
			LLVMAddPruneEHPass(self);
		else if (strcmp(spass, "IPSCCP") == 0)
			LLVMAddIPSCCPPass(self);
		else if (strcmp(spass, "Internalize") == 0)
			LLVMAddInternalizePass(self, 1);
		else if (strcmp(spass, "StripDeadPrototypes") == 0)
			LLVMAddStripDeadPrototypesPass(self);
		else if (strcmp(spass, "StripSymbols") == 0)
			LLVMAddStripSymbolsPass(self);
		# Scalar transformations
		else if (strcmp(spass, "AggressiveDCE") == 0)
			LLVMAddAggressiveDCEPass(self);
		else if (strcmp(spass, "CFGSimplification") == 0)
			LLVMAddCFGSimplificationPass(self);
		else if (strcmp(spass, "DeadStoreElimination") == 0)
			LLVMAddDeadStoreEliminationPass(self);
		else if (strcmp(spass, "GVN") == 0)
			LLVMAddGVNPass(self);
		else if (strcmp(spass, "IndVarSimplify") == 0)
			LLVMAddIndVarSimplifyPass(self);
		else if (strcmp(spass, "InstructionCombining") == 0)
			LLVMAddInstructionCombiningPass(self);
		else if (strcmp(spass, "JumpThreading") == 0)
			LLVMAddJumpThreadingPass(self);
		else if (strcmp(spass, "LICMP") == 0)
			LLVMAddLICMPass(self);
		else if (strcmp(spass, "LoopDeletion") == 0)
			LLVMAddLoopDeletionPass(self);
		else if (strcmp(spass, "LoopIdiom") == 0)
			LLVMAddLoopIdiomPass(self);
		else if (strcmp(spass, "LoopRotate") == 0)
			LLVMAddLoopRotatePass(self);
		else if (strcmp(spass, "LoopUnroll") == 0)
			LLVMAddLoopUnrollPass(self);
		else if (strcmp(spass, "LoopUnswitch") == 0)
			LLVMAddLoopUnswitchPass(self);
		else if (strcmp(spass, "MemCpyOpt") == 0)
			LLVMAddMemCpyOptPass(self);
		else if (strcmp(spass, "PromoteMemoryToRegister") == 0)
			LLVMAddPromoteMemoryToRegisterPass(self);
		else if (strcmp(spass, "Reassociate") == 0)
			LLVMAddReassociatePass(self);
		else if (strcmp(spass, "SCCP") == 0)
			LLVMAddSCCPPass(self);
		else if (strcmp(spass, "ScalarReplAggregates") == 0)
			LLVMAddScalarReplAggregatesPass(self);
		else if (strcmp(spass, "SimplifyLibCall") == 0)
			LLVMAddSimplifyLibCallsPass(self);
		else if (strcmp(spass, "TailCallElimination") == 0)
			LLVMAddTailCallEliminationPass(self);
		else if (strcmp(spass, "ConstantPropagation") == 0)
			LLVMAddConstantPropagationPass(self);
		else if (strcmp(spass, "DemoteMemoryToRegoster") == 0)
			LLVMAddDemoteMemoryToRegisterPass(self);
		else if (strcmp(spass, "Verifier") == 0)
			LLVMAddVerifierPass(self);
		else if (strcmp(spass, "CorrelatedValuePropagation") == 0)
			LLVMAddCorrelatedValuePropagationPass(self);
		else if (strcmp(spass, "EarlyCSE") == 0)
			LLVMAddEarlyCSEPass(self);
		else if (strcmp(spass, "LowerExpectIntrinsic") == 0)
			LLVMAddLowerExpectIntrinsicPass(self);
		else if (strcmp(spass, "TypeBasedAliasAnalysis") == 0)
			LLVMAddTypeBasedAliasAnalysisPass(self);
		else if (strcmp(spass, "BasicAliasAnalysis") == 0)
			LLVMAddBasicAliasAnalysisPass(self);
		# Vectorize transformations
		else if (strcmp(spass, "BBVectorize") == 0)
			LLVMAddBBVectorizePass(self);
		else
			Perl_croak(aTHX_ "invalid pass '%s'", spass);

void
DESTROY(self)
	PassManager self

	CODE:
		LLVMDisposePassManager(self);
