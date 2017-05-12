package Dummy::Repo;
use strict;
use warnings;
use v5.10.0;
use Carp;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @EXPORT @ISA);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    @EXPORT      = qw( word p51 );
}

sub word { return shift };

sub p51 {
    my $n = shift;
    croak "Must pass an integer to p51()"
        unless $n =~ m/^[+-]?\d+$/;
    return $n + 51;
}

=head1 NAME

Dummy::Repo - A repo solely for testing other git repos

=head1 SYNOPSIS

    use Dummy::Repo;
    use Test::More qw(no_plan);

    my ($word, $rv);
    $word = 'alpha';
    $rv = word($word);
    is($rv, $word, "Got expected word: $word");

    my ($n);
    $n = 7;
    $rv = p51($n);
    is($rv, $n + 51, "Got expected sum: $rv);

=head1 DESCRIPTION

This library exists solely for the purpose of providing a git repository to be
used in the testing of other git repositories or git functionality.

This library is set up in the form of a CPAN-ready Perl distribution
consisting of:

=over 4

=item *

A module, F<Dummy::Repo>,  which exports two subroutines:

=over 4

=item * C<word()>

C<word()> does nothing but return a string provided as its argument.

=item * C<p51()>

C<p51()> does nothing but add 51 to the positive or negative integer provided as its argument.

=back

=item *

Two test files:

=over 4

=item * F<t/001_load.t>, which confirms that C<word()> works as expected.

This file is present in all commits in this repository.

=item * F<t/002_add.t>, which confirms that C<p51()> works as expected.

This file is not present in all commits in this repository.

=back

=back

What is more important is the fact that F<t/001_load.t> has been modified in a
series of commits, sometimes to change the word used in testing C<word()> and
sometimes only to add or subtract whitespace within the test file.  We end up
with a series of commits which can each be tested with:

    prove -vb t/001_load.t

The objective is to generate B<differences> in the output of F<prove> at
certain commits but not other commits.

=head1 AUTHOR

James E Keenan (jkeenan at cpan dot org).  Copyright 2016.

=cut

1;

