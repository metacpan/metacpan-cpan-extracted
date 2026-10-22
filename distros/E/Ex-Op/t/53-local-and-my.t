#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Ex::Op ();
use EO::OpTwin;

our $G = 'g';
our @A = (1);
our %H = (k => 'v');

BEGIN {
    Ex::Op::make(locals => sub { my ($x) = @_; local $G = $x; local @A = ($x); local $H{k} = $x; "$G@A$H{k}" });
    Ex::Op::make(capture_param => sub { my ($x) = @_; sub { $x } });
    Ex::Op::make(capture_my    => sub { my ($x) = @_; my $t = $x * 10; sub { $t } });
    Ex::Op::make(counter       => sub { my ($x) = @_; state $n = 0; $n += $x; $n });
    Ex::Op::make(fresh_my      => sub { my ($x) = @_; my $t; $t .= $x; $t });
    Ex::Op::make(fresh_arr     => sub { my ($x) = @_; my @a; push @a, $x; scalar @a });
}
use feature 'state';

sub t_locals { my $r = locals('z'); [$r, $G, "@A", $H{k}] }
is_deeply( t_locals(), ['zzz', 'g', '1', 'v'], 'local scalars, arrays and hash elements are undone at the end of the call' );

is( Ex::Op::why_not(\&capture_param), q{it makes a closure over its own variables}, q{a body that makes a closure over a parameter is declined} );
is( Ex::Op::why_not(\&capture_my), q{it makes a closure over its own variables}, q{... and over a my in the body} );
sub t_capture_param { my @c = map { capture_param($_) } 1 .. 3; [map { $_->() } @c] }
is_deeply( t_capture_param(), [1, 2, 3], q{... and still works as a plain sub} );
sub t_capture_my { my @c = map { capture_my($_) } 1 .. 3; [map { $_->() } @c] }
is_deeply( t_capture_my(), [10, 20, 30], q{... both} );

BEGIN { Ex::Op::make(anon_plain => sub { my ($x) = @_; my $f = sub { 2 * $_[0] }; $f->($x) }) }
ok( Ex::Op::is_op(\&anon_plain), q{an anon sub that captures nothing is fine} );
sub t_anon_plain { my $r = anon_plain(21); $r }
is( t_anon_plain(), 42, q{... and runs} );

sub t_state { my @r = map { counter($_) } 1 .. 4; \@r }
is_deeply( t_state(), [1, 3, 6, 10], 'a state variable lasts between calls' );

sub t_fresh { my @r = map { fresh_my($_) } qw(a b c); \@r }
is_deeply( t_fresh(), [qw(a b c)], 'a my in the body is fresh on every call' );

sub t_fresh_arr { my @r = map { fresh_arr($_) } 1 .. 3; \@r }
is_deeply( t_fresh_arr(), [1, 1, 1], '... an array too' );

SKIP: {
    skip q{qr code blocks are closures from perl 5.18}, 1 if $] < 5.018;
    my $code = eval q{ sub { my ($x) = @_; my $r = qr/(?{ $x })/; 1 } } or die $@;
    Ex::Op::make(qr_code => $code);
    is( Ex::Op::why_not($code), q{it makes a qr with a code block}, q{a qr with a code block is declined} );
}

twin_all( 'locals', 'my ($x) = @_; local $main::G = $x; $main::G . $main::G', 'q' );
twin_all( 'a my shadowing a parameter name', 'my ($x) = @_; { my $x = "inner"; } $x', 'outer' );

done_testing;
