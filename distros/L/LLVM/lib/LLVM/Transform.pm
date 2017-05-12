package LLVM::Transform;
{
  $LLVM::Transform::VERSION = '0.10';
}

use strict;
use warnings;

=head1 NAME

LLVM::Transform - LLVM transformation class

=head1 VERSION

version 0.10

=head1 DESCRIPTION

See the L<LLVM reference|http://llvm.org/docs/Passes.html#transforms> for more
information about the single transformations.

=head1 INTERPROCEDURAL TRANSFORMATIONS

=head2 ArgumentPromotion

=head2 ConstantMerge

=head2 DeadArgElimination

=head2 FunctionAttrs

=head2 FunctionInlining

=head2 AlwaysInliner

=head2 GlobalDCE

=head2 GlobalOptimizer

=head2 IPConstantPropagation

=head2 PruneEH

=head2 IPSCCP

=head2 Internalize

=head2 StripDeadPrototypes

=head2 StripSymbols

=head1 SCALAR TRANSFORMATIONS

=head2 AggressiveDCE

=head2 CFGSimplification

=head2 DeadStoreElimination

=head2 GVN

=head2 IndVarSimplify

=head2 InstructionCombining

=head2 JumpThreading

=head2 LICMP

=head2 LoopDeletion

=head2 LoopIdiom

=head2 LoopRotate

=head2 LoopUnroll

=head2 LoopUnswitch

=head2 MemCpyOpt

=head2 PromoteMemoryToRegister

=head2 Reassociate

=head2 SCCP

=head2 ScalarReplAggregates

=head2 SimplifyLibCall

=head2 TailCallElimination

=head2 ConstantPropagation

=head2 DemoteMemoryToRegoster

=head2 Verifier

=head2 CorrelatedValuePropagation

=head2 EarlyCSE

=head2 LowerExpectIntrinsic

=head2 TypeBasedAliasAnalysis

=head2 BasicAliasAnalysis

=head1 VECTORIZE TRANSFORMATIONS

=head2 BBVectorize

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of LLVM::Transform
