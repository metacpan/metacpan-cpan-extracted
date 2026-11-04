#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Ex::Op ();

no strict 'refs';
our @shared = (1, 2);

my @decline = (
    [ '\*_',                   'it uses *_',                                   sub { my ($x) = @_; my $g = \*_; $x } ],
    [ 'my () = @_',            'its first statement assigns @_ to something other than new scalars', sub { my () = @_; scalar @_ } ],
);
for my $case (@decline) {
    my ($desc, $why, $code) = @$case;
    (my $name = "dec_$desc") =~ s/\W+/_/g;
    ok( !Ex::Op::make($name, $code), "declined: $desc" );
    is( Ex::Op::why_not($code), $why, "... because $why" );
}

my @accept = (
    [ '\*STDOUT',              sub { my ($x) = @_; my $g = \*STDOUT; $x } ],
    [ 'qr without a code block', sub { my ($x) = @_; my $re = qr/a/; $x =~ $re ? 1 : 0 } ],
    [ 'shift of its own array', sub { my ($x) = @_; my @l = ($x, 2); shift @l } ],
    [ 'an element of a global array', sub { my ($x) = @_; $main::shared[1] } ],
    [ 'a first statement that assigns from another array', sub { my ($x) = @main::shared; $x } ],
);
for my $case (@accept) {
    my ($desc, $code) = @$case;
    (my $name = "acc_$desc") =~ s/\W+/_/g;
    ok( Ex::Op::make($name, $code), "accepted: $desc" );
    is( Ex::Op::why_not($code), undef, '... with no reason not to be' );
}
is( acc_an_element_of_a_global_array(1), 2, 'the global array element is read' );
is( acc_shift_of_its_own_array(5), 5, 'the shift is of the local array' );
is( acc_a_first_statement_that_assigns_from_another_array(9), 1, 'a first statement that is not the binding leaves the op with no parameters, and runs' );

{
    require EO::NoWarn;
    ok( Ex::Op::make('EO::NoWarn::plus_one', \&EO::NoWarn::plus_one), 'a sub from a file with no lexical warnings is an op' );
    is( EO::NoWarn::plus_one(1), 2, '... and runs' );
}

{
    Ex::Op::make(gone_then_called => sub { my ($x) = @_; $x });
    undef &gone_then_called;
    my $r = eval q{ no warnings 'redefine'; sub gone_then_called { my ($x) = @_; $x + 10 } gone_then_called(1) };
    is( $r, 11, 'a call compiled after the op was undefined and redefined is an ordinary call' );
    Ex::Op::make(gone_for_good => sub { my ($x) = @_; $x });
    undef &gone_for_good;
    eval q{ gone_for_good(1) };
    like( $@, qr/^Undefined subroutine/, 'a call compiled after the op was undefined is an ordinary call too' );
}

done_testing;
