package LLVM;

use strict;
use warnings;

require XSLoader;
XSLoader::load('LLVM', $LLVM::VERSION);

=head1 NAME

LLVM - Perl bindings to the Low Level Virtual Machine

=head1 SYNOPSIS

    use LLVM;

    # create a new LLVM context and a module named "synopsis"
    my $mod = LLVM::Module -> new("synopsis");

    # create a new function type that takes 2 ints and returns one int
    my $intt = LLVM::Type -> int(32);
    my $funt = LLVM::Type -> func($intt, $intt, $intt);

    # add a new function to the module with the just-created type
    my $fun = $mod -> add_func("add", $funt);

    # set function's parameters names
    my $params = $fun -> func_params;

    $params -> [0] -> name("x");
    $params -> [1] -> name("y");

    # create a new instruction builder
    my $bld = LLVM::Builder -> new;

    # create a new entry block for the "add" function and position the
    # builder at its end
    my $blk = $fun -> func_append("entry");
    $bld -> position_at_end($blk);

    # create an "add" intruction and use its return value as function return
    my $tmp = $bld -> add($params -> [0], $params -> [1], "tmp");
    $bld -> ret($tmp);

    # dump the LLVM IR to stderr
    $mod -> dump;

The output should look like this:

    ; ModuleID = 'synopsis'

    define i32 @add(i32 %x, i32 %y) {
    entry:
      %tmp = add i32 %x, %y
      ret i32 %tmp
    }

Once the module is created, a number of optimizations can be applied:

    # create a new LLVM::PassManager
    my $mgr = LLVM::PassManager -> new;

    # schedule a couple of passes
    $mgr -> add("FunctionInlining");
    $mgr -> add("GlobalDCE");

    # run the pass manager on the module
    $mgr -> run($mod);

And finally the module can be compiled in-memory and executed:

    # create the arguments for the function call
    my $arg1 = LLVM::GenericValue -> int($intt, 5);
    my $arg2 = LLVM::GenericValue -> int($intt, 10);

    # create an execution engine for the module
    my $eng = LLVM::ExecutionEngine -> new($mod);

    # call the function "add" and print the result
    my $result = $eng -> run_func($fun, $arg1, $arg2);

    say $result -> to_int;

Or compiled to object code:

    # get the first target available
    my $target = LLVM::Target -> targets -> [0];

    # create a target machine
    my $tm = LLVM::TargetMachine -> create(
      $target, 'x86_64-linux-gnu', 'penryn', ['64bit']
    );

    # emit the object code to disk
    $tm -> emit($mod, 'synopsis.o', 1);

=head1 DESCRIPTION

The Low-Level Virtual Machine (LLVM) is a collection of libraries and tools
that make it easy to build compilers, optimizers, Just-In-Time code generators,
and many other compiler-related programs. This module provides Perl bindings to
the LLVM API.

B<Note>: LLVM v3.1 is required to build this distribution.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of LLVM
