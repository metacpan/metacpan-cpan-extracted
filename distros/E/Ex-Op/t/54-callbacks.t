#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Ex::Op ();

BEGIN {
    Ex::Op::make(add    => sub { my ($x, $y) = @_; $x + $y });
    Ex::Op::make(twice  => sub { my ($x) = @_; $x * 2 });
    Ex::Op::make(by_num => sub { $a <=> $b });
}

sub t_sort { my @s = sort { add($a, 0) <=> add($b, 0) } 3, 1, 2; \@s }
is_deeply( t_sort(), [1, 2, 3], 'called from a sort block' );

sub t_sort_sub { my @s = sort by_num 3, 1, 2; \@s }
is_deeply( t_sort_sub(), [1, 2, 3], 'an op used as the sort sub' );

sub t_map  { my @m = map { twice($_) } 1 .. 3; \@m }
is_deeply( t_map(), [2, 4, 6], 'called from a map block' );

sub t_grep { my @g = grep { twice($_) > 2 } 1 .. 3; \@g }
is_deeply( t_grep(), [2, 3], 'called from a grep block' );

my @destroyed;
{
    package EO::CB::Obj;
    sub new     { my ($c, $v) = @_; bless { v => $v }, $c }
    sub DESTROY { push @destroyed, main::twice($_[0]{v}) }
}
sub t_destroy { { my $o = EO::CB::Obj->new(5) } \@destroyed }
is_deeply( t_destroy(), [10], 'called from DESTROY' );

{
    package EO::CB::Tied;
    sub TIESCALAR { bless [] }
    sub FETCH     { main::add(20, 1) }
}
sub t_tie { tie my $t, 'EO::CB::Tied'; my $r = twice($t); $r }
is( t_tie(), 42, 'called from FETCH, while another op copies the tied argument' );

{
    package EO::CB::Grow;
    sub TIESCALAR { bless [] }
    sub FETCH     { my @big = (1) x 1_000_000; scalar(@big) ? 7 : 0 }
}
BEGIN { Ex::Op::make(pair => sub { my ($x, $y) = @_; "$x:$y" }) }
sub t_grow { tie my $t, q{EO::CB::Grow}; my $r = pair($t, q{second}); $r }
is( t_grow(), q{7:second}, q{a tied argument whose FETCH grows the Perl stack: the next argument is still read right} );

sub t_warn {
    my $got;
    local $SIG{__WARN__} = sub { $got = twice(length $_[0]) };
    warn "abc\n";
    $got;
}
is( t_warn(), 8, 'called from a $SIG{__WARN__} handler' );

sub t_string_eval { my $r = eval 'my $q = add(2, 2); $q'; $r }
is( t_string_eval(), 4, 'called from a string eval' );

sub t_eval_block { my $r = eval { my $q = add(3, 3); $q }; $r }
is( t_eval_block(), 6, 'called from an eval block' );

sub t_eval_direct { my $r = eval { add(4, 4) }; $r }
is( t_eval_direct(), 8, 'called as the last thing in an eval block' );

{
    my $r = add(5, 5);
    is( $r, 10, 'called at file level' );
}

done_testing;
