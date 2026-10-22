#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use B::Concise ();
use Ex::Op ();

sub early { my $r = add(1, 2); $r }

BEGIN { Ex::Op::make(add => sub { my ($x, $y) = @_; $x + $y }) }
BEGIN { Ex::Op::make(back => sub { my ($x) = @_; wantarray }) }

sub later   { my $r = add(1, 2); $r }
sub amp     { my $r = &add(1, 2); $r }
sub nested  { my $r = add(add(1, 2), 3); $r }
sub declined { my $r = back(1); $r }

sub ops_of {
    my ($name) = @_;
    my $out = '';
    B::Concise::walk_output(\$out);
    B::Concise::compile('-exec', $name)->();
    return $out;
}

like(   ops_of('main::later'), qr/\bexop_call\b/, 'a call compiled after make is an exop_call' );
unlike( ops_of('main::later'), qr/\bentersub\b/,      '... and not an entersub' );
like(   ops_of('main::early'), qr/\bentersub\b/,      'a call compiled before make stays an entersub' );
like(   ops_of('main::amp'),   qr/\bentersub\b/,      '&add(...) stays an entersub' );
my @calls = ops_of('main::nested') =~ /\bexop_call\b/g;
is( scalar @calls, 2, 'both calls in add(add(...)) are rewritten' );
like(   ops_of('main::declined'), qr/\bentersub\b/,   'a call to a declined sub stays an entersub' );

is( later(), 3, 'and the rewritten call runs' );

done_testing;
