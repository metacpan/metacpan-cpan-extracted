#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Oracle;

my $body = <<'BODY';
our $VERSION     = '1.00';
our @EXPORT      = qw(d1 &d2 $dv);
our @EXPORT_OK   = qw(o1 o2 @oa %oh *og risky);
our %EXPORT_TAGS = (t1 => [qw(d1 o1)], t2 => [qw($dv @oa o2)]);
our @EXPORT_FAIL = qw(risky);
sub export_fail { my $class = shift; @_ }
sub d1 { 'd1' } sub d2 { 'd2' } sub o1 { 'o1' } sub o2 { 'o2' }
sub og { 'og' } sub risky { 'risky' }
our $dv = 'dv';
our @oa = (1);
our %oh = (k => 1);
our $og = 'og';
BODY

my @pool = (
    'd1', '&d2', '$dv', 'o1', '@oa', '*og', 'risky', 'nope',
    ':t1', ':t2', ':DEFAULT', ':nosuch',
    '!d1', '!:t1', '/o/', '!/d/',
    '0.5', '',
);

my $depth = $ENV{EX_OP_SWEEP} ? 4 : 3;

my @lists = ([]);
my @frontier = ([]);
for my $d (1 .. $depth) {
    @frontier = map { my $l = $_; map { [@$l, $_] } @pool } @frontier;
    push @lists, @frontier;
}

# After a spec walk Exporter holds the names in a hash, and its rule for a
# version followed by a false entry (import nothing) reads the second
# element. With a spec, a version and a false entry in one list, which
# element is second is the hash's choice, and Exporter's own answer changes
# with PERL_HASH_SEED. Those lists are compared without the error.
sub hash_ordered {
    my @l = @_;
    return (grep { m{^[/!:]} } @l) && (grep { /^\d/ } @l) && (grep { !$_ } @l);
}

my $pkgs = EO::Oracle::build('import', $body);
my ($runs, $ordered, @bad, @unsteady) = (0, 0);
for my $list (@lists) {
    my $r = EO::Oracle::run($pkgs, @$list);
    $runs++;
    if (hash_ordered(@$list)) {
        $ordered++;
        delete $r->{$_}{error} for qw(E X);
        my $again = EO::Oracle::run($pkgs, @$list);
        my $first = EO::Oracle::run($pkgs, @$list);
        push @unsteady, $list unless EO::Oracle::show($again->{X}) eq EO::Oracle::show($first->{X});
    }
    push @bad, [$list, $r] unless EO::Oracle::same($r);
}

is( scalar @bad, 0, "every list of up to $depth specs from " . scalar(@pool) . " imports as Exporter does ($runs lists)" );
is( scalar @unsteady, 0, "$ordered lists that Exporter answers by hash order are compared without the error, and Ex::Op answers each the same way every time" );
for my $b (@bad[0 .. ($#bad < 9 ? $#bad : 9)]) {
    my ($list, $r) = @$b;
    diag "list: [" . join(', ', map { "'$_'" } @$list) . "]\n"
       . "Exporter:\n" . EO::Oracle::show($r->{E})
       . "Ex::Op:\n" . EO::Oracle::show($r->{X});
}

done_testing;
