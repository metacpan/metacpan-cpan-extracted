#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Ex::Op ();

{ package EO::TiedP; sub TIESCALAR { bless {}, shift } sub FETCH { 't' } sub STORE { } }

BEGIN {
    Ex::Op::make(ties       => sub { my ($x) = @_; tie $x, 'EO::TiedP'; $x });
    Ex::Op::make(ro         => sub { my ($x) = @_; Internals::SvREADONLY($x, 1); $x });
    Ex::Op::make(globbed    => sub { my ($x) = @_; $x = *STDOUT; 1 });
    Ex::Op::make(gives_glob => sub { *STDOUT });
    Ex::Op::make(pair       => sub { my ($x) = @_; my @a = ($x, $x); @a });
    Ex::Op::make(add1       => sub { my ($x) = @_; $x + 1 });
    Ex::Op::make(vanish     => sub { my ($x) = @_; $x });
}

sub drive {
    my @r;
    push @r, ties(1), ties(2), ro(3), ro(4), globbed(5), globbed(6);
    return @r;
}
is_deeply( [drive()], ['t', 't', 3, 4, 1, 1], 'a parameter tied, made read only or given a glob in the body is replaced for the next call' );

sub glob_of { my $g = gives_glob(); return ref \$g }
is( glob_of(), 'GLOB', 'a glob returned in scalar context is copied as one' );

{
    my $c = eval 'sub { vanish(1) }' or die $@;
    undef *main::vanish;
    eval { $c->() };
    like( $@, qr/^Undefined subroutine &main::vanish called/, 'a call whose glob has lost its sub is an ordinary call, and fails as one' );
}

{
    local $^P = $^P | 0x01;
    is( add1(1), 2, 'with sub tracing on the call is an ordinary one' );
}

{
    my @v;
    eval { for my $i (1) { @v = pair($i) } };
    is_deeply( \@v, [1, 1], 'a call whose result depends on its context, in a loop inside an eval block' );
}

done_testing;
