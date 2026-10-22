#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::OpTwin;

twin_all( 'a missing argument',   'my ($x, $y) = @_; defined $y ? "def" : "undef"', 1 );
twin_all( 'no arguments',         'my ($x, $y) = @_; join ",", map { defined $_ ? $_ : "u" } $x, $y' );
twin_all( 'extra arguments',      'my ($x) = @_; $x', 1, 2, 3 );
twin_all( 'an array flattens',    'my ($x, $y, $z) = @_; "$x$y$z"', (my @a = (1, 2, 3)) );
twin_all( 'undef arguments',      'my ($x, $y) = @_; (defined $x ? 1 : 0) . (defined $y ? 1 : 0)', undef, 0 );
twin_all( 'a reference argument', 'my ($r) = @_; scalar @$r', [1, 2] );

{
    my $c = EO::OpTwin::twin('my ($x) = @_; $x .= "!"; $x');
    my $v = 'keep';
    my $r = $c->{op}{scalar}->($v);
    is( $r->[0], 'keep!', 'a parameter can be changed in the body' );
    is( $v, 'keep', '... and is a copy: the caller\'s value is untouched' );
}

{
    my $c = EO::OpTwin::twin('my ($x, $y) = @_; $x');
    my $n = 0;
    my $r = $c->{op}{scalar}->(1, $n++, $n++);
    is( $n, 2, 'extra arguments are still evaluated' );
}

{
    my $c = EO::OpTwin::twin('my ($x) = @_; defined $x ? 1 : 0');
    my %h;
    my $r = $c->{op}{scalar}->($h{nope});
    ok( !exists $h{nope}, 'a hash element that does not exist is not created' );
}

{
    my $c = EO::OpTwin::twin('my ($x) = @_; $x');
    'a123' =~ /(\d+)/;
    my $r = $c->{op}{scalar}->($1);
    is( $r->[0], 123, '$1 as an argument' );
}

done_testing;
