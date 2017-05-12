package Devel::Mutator;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.03";

1;
__END__
=pod

=encoding utf-8

=head1 NAME

Devel::Mutator - Mutation testing for Perl

=head1 SYNOPSIS

    mutator mutate lib/MyModule.pm
    mutator test

=head1 DESCRIPTION

Devel::Mutator is a mutation testing toolkit for Perl. Mutation testing is
changing the working program in different ways and checking that the test suite
fails and thus detecting the bad testing.

=head2 How it works

First we generate mutated code. For example every occurance of C<=> is replaced
by C<!=>. All the mutants are collected in the C<mutants/> directory. Then we
run the tests replacing original code by the mutant. If the test suite does not
fail when the code is changed it is reported with a C<diff> output, which helps
to see the problem.

    (10/18) ./mutants/7021082cc1c0afbe9322f60a9b5e5d5f/lib/Input/Validator/Field.pm ... not ok
    --- ./mutants/7021082cc1c0afbe9322f60a9b5e5d5f/lib/Input/Validator/Field.pm Sat Nov  1 11:27:00 2014
    +++ lib/Input/Validator/Field.pm.bak    Sun May 18 21:50:14 2014
    @@ -14,7 +14,7 @@
         my $self = shift;

         $self->{constraints} ||= [];
    -    $self->{messages}    //= {};
    +    $self->{messages}    ||= {};

         $self->{trim} = 1 unless defined $self->{trim};

Here we can see that the test suite does not check the need for C<//>.

=head2 Warning

The original code is replaced by the mutants, so make sure it is under a VCS if
something bad happens.  This is the easiest and the 100% working way. Maybe
this will be changed in the future when a better way is found.

=head2 Mutation testing drawbacks

There are several drawbacks.

=head3 The equivalent program

The equivalent program can be produced thus failing the test. There is no
solution to that for now.

=head3 Infinite loops

Infinite loops can be created easily. The solution is to run the test suite
limited in time through a C<timeout> option, which is 10s by default. After 10s
of running, the test suite is killed and C<n/a timeout> is reported.

=head1 METHODS

=head1 CREDITS

Alexandr Ciornii (chorny)

Tim Teasdale (hooverbag)

Patricio Valle (pvallev)

=head1 AUTHOR

Viacheslav Tykhanovskyi, E<lt>viacheslav.t@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.

=cut
