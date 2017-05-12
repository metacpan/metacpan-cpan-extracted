#!perl -T

use Test::More;
use File::Slurp;
use Capture::Tiny 'capture_stderr';

use LLVM;

my $mod = LLVM::Module -> new("test1");
my $bld = LLVM::Builder -> new;

my $intt = LLVM::Type -> int(32);
my $funt = LLVM::Type -> func($intt, $intt, $intt, $intt);

my $fun = $mod -> add_func("test1", $funt);

my $params = $fun -> func_params;

$params -> [0] -> name("x");
is $params -> [0] -> name, "x";

$params -> [1] -> name("y");
is $params -> [1] -> name, "y";

$params -> [2] -> name("z");
is $params -> [2] -> name, "z";

my $blk = $fun -> func_append("entry");

$bld -> position_at_end($blk);

my $tmp1 = $bld -> add($params -> [0], $params -> [1], "tmp1");
my $tmp2 = $bld -> mul($tmp1, $params -> [2], "tmp2");

$bld -> ret($tmp2);

my $stderr = capture_stderr { $mod -> dump };

my $expected = <<'EOS';
; ModuleID = 'test1'

define i32 @test1(i32 %x, i32 %y, i32 %z) {
entry:
  %tmp1 = add i32 %x, %y
  %tmp2 = mul i32 %tmp1, %z
  ret i32 %tmp2
}
EOS

is $stderr, $expected;

my $pass = LLVM::PassManager -> new;

$pass -> add("GlobalDCE");
$pass -> add("ArgumentPromotion");
$pass -> add("ConstantMerge");
$pass -> add("DeadArgElimination");
$pass -> add("FunctionAttrs");
$pass -> add("FunctionInlining");
$pass -> add("AlwaysInliner");
$pass -> add("GlobalDCE");
$pass -> add("GlobalOptimizer");
$pass -> add("IPConstantPropagation");
$pass -> add("PruneEH");
$pass -> add("IPSCCP");
$pass -> add("Internalize");
$pass -> add("StripDeadPrototypes");
$pass -> add("StripSymbols");
$pass -> add("AggressiveDCE");
$pass -> add("CFGSimplification");
$pass -> add("DeadStoreElimination");
$pass -> add("GVN");
$pass -> add("IndVarSimplify");
$pass -> add("InstructionCombining");
$pass -> add("JumpThreading");
$pass -> add("LICMP");
$pass -> add("LoopDeletion");
$pass -> add("LoopIdiom");
$pass -> add("LoopRotate");
$pass -> add("LoopUnroll");
$pass -> add("LoopUnswitch");
$pass -> add("MemCpyOpt");
$pass -> add("PromoteMemoryToRegister");
$pass -> add("Reassociate");
$pass -> add("SCCP");
$pass -> add("ScalarReplAggregates");
$pass -> add("SimplifyLibCall");
$pass -> add("TailCallElimination");
$pass -> add("ConstantPropagation");
$pass -> add("DemoteMemoryToRegoster");
$pass -> add("Verifier");
$pass -> add("CorrelatedValuePropagation");
$pass -> add("EarlyCSE");
$pass -> add("LowerExpectIntrinsic");
$pass -> add("TypeBasedAliasAnalysis");
$pass -> add("BasicAliasAnalysis");
$pass -> add("BBVectorize");

$pass -> run($mod);

$stderr = capture_stderr { $mod -> dump };

$expected = <<'EOS';
; ModuleID = 'test1'

define i32 @test1(i32, i32, i32) nounwind readnone {
  %4 = add i32 %1, %0
  %5 = mul i32 %4, %2
  ret i32 %5
}
EOS

is $stderr, $expected;

my $arg1 = LLVM::GenericValue -> int($intt, 10);
my $arg2 = LLVM::GenericValue -> int($intt, 15);
my $arg3 = LLVM::GenericValue -> int($intt, 20);

my $eng = LLVM::ExecutionEngine -> new($mod);

my $res = $eng -> run_func($fun, $arg1, $arg2, $arg3);

is $res -> to_int, 500;

my $targets = LLVM::Target -> targets;

my $tm = LLVM::TargetMachine -> create(
	$targets -> [0], 'x86_64-linux-gnu',
	'penryn', ['64bit', '64bit-mode', 'avx']
);

$tm -> emit($mod, 't/basic.out', 0);

$expected = <<'EOS';
	.file	"test1"
	.text
	.globl	test1
	.align	16, 0x90
	.type	test1,@function
test1:
	addl	%esi, %edi
	imull	%edx, %edi
	movl	%edi, %eax
	ret
.Ltmp0:
	.size	test1, .Ltmp0-test1


	.section	".note.GNU-stack","",@progbits
EOS

is read_file('t/basic.out'), $expected;

done_testing;
