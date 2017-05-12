#!/usr/bin/perl

use strict;
use warnings;
use threads;
# When Kappa keyword Perl is available, then variables can be
# shared between this main perl interpreter and the perl interpreters
# running as 'kernels' in the scheduled execution context.
# Perl interpreters do not run on the GPU--they run on the CPU's
# --but when they are running in the scheduled execution context they can
# access the Kappa Variables and properties of of the CUDA GPU
# for the given CUDA GPU context.
use threads::shared;
use Test::Simple tests => 12;
use KappaCUDA;

my $filename = shift;
if (!$filename) {
  $filename = 'test1.k';
}

my $kappa = KappaCUDA::Kappa::Instance("","",0);
ok( defined $kappa, 'retrieved Kappa instance');
my $process = $kappa->GetProcess(0,0);
ok( defined $process, 'retrieved Process for gpu number 0');

ok( $process->ExecuteString (
'<kappa>' . "\n" .
'!Context ->  context;' . "\n" .
'</kappa>' . "\n"
), 'Setup Context');

ok( $process->ExecuteString (
'<kappa>' . "\n" .
'!Value -> WA = (3 * {BLOCK_SIZE}); // Matrix A width' . "\n" .
'!Value -> HA = (5 * {BLOCK_SIZE}); // Matrix A height' . "\n" .
'!Value -> WB = (8 * {BLOCK_SIZE}); // Matrix B width' . "\n" .
'!Value -> HB = #WA;                // Matrix B height' . "\n" .
'!Value -> WC = #WB;                // Matrix C width' . "\n" .
'!Value -> HC = #HA;                // Matrix C height' . "\n" .
'</kappa>' . "\n"
), 'Setup dimensions');

ok( $process->ExecuteString (
'<kappa>' . "\n" .
'!CUDA/Module MODULE_TYPE=%KAPPA{CU_MODULE} -> matrixMul = \'matrixMul_kernel.cu\';' . "\n" .
'</kappa>' . "\n"
), 'Load matrixMul_kernel ptx');

ok( $process->ExecuteString (
'<kappa>' . "\n" .
'!Variable -> A(#WA,#HA,%sizeof{float});' . "\n" .
'!Variable -> B(#WB,#HB,%sizeof{float});' . "\n" .
'!Variable VARIABLE_TYPE=%KAPPA{Device} DEVICEMEMSET=true ' . "\n" .
'-> C(#WC,#HC,%sizeof{float});' . "\n" .
'</kappa>' . "\n"
), 'Create Variables');

ok( $process->ExecuteString (
'<kappa>' . "\n" .
'!Free -> A;' . "\n" .
'!Free -> B;' . "\n" .
'!Free -> C;' . "\n" .
'</kappa>' . "\n"
), 'Free Variables');

ok( $process->ExecuteString (
'<kappa>' . "\n" .
'!CUDA/Kernel/Attributes MODULE=matrixMul -> matrixMul;' . "\n" .
'</kappa>' . "\n"
), 'Get CUDA kernel attributes');

ok( $process->ExecuteString (
'<kappa>' . "\n" .
'!CUDA/ModuleUnload -> matrixMul;' . "\n" .
'</kappa>' . "\n"
), 'Unload CUDA module');

ok( $process->ExecuteString (
'<kappa>' . "\n" .
'!ContextReset -> Context_reset;' . "\n" .
'</kappa>' . "\n"
), 'Reset context');

ok( $process->ExecuteString (
'<kappa>' . "\n" .
'!Stop;' . "\n" .
'!Finish;' . "\n" .
'</kappa>' . "\n"
), 'Stop and Finish');

ok( $kappa->WaitForAll(), 'waited for completion');
exit 0;

