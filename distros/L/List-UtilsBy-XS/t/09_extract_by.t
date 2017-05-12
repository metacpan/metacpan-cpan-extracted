use strict;
use warnings;

use Test::More;
use Scalar::Util qw( weaken isweak );

use List::UtilsBy::XS qw(extract_by);

# We'll need a real array to work on
my @numbers = ( 1 .. 10 );
my @gots;
my $expected;

@gots = extract_by { 0 } @numbers;
is_deeply(\@gots , [], 'extract false returns none' );
is_deeply( \@numbers, [ 1 .. 10 ], 'extract false leaves array unchanged');

@gots = extract_by { $_ % 3 == 0 } @numbers;
$expected = [ 3, 6, 9 ];
is_deeply(\@gots, $expected, 'extract div3 returns values');
$expected = [ 1, 2, 4, 5, 7, 8, 10 ];
is_deeply( \@numbers, $expected, 'extract div3 removes from array');

@gots = extract_by { 1 } @numbers;
$expected = [ 1, 2, 4, 5, 7, 8, 10 ];
is_deeply(\@gots, $expected, 'extract true returns all') || diag explain \@gots;
is_deeply( \@numbers, [], 'extract true leaves nothing' );

subtest 'scalar context' => sub {
    my @input = qw(a b c d e f);
    my $g = extract_by { 1 } @input;
    is $g, 6, "Return list length in scalar context";

    my @input2 = qw(a b c d e f);
    my $g2 = extract_by { m/\A[bd]\z/ } @input2;
    is $g2, 2;
};

TODO: {
    todo_skip "not implemented", 6;

    my @refs = map { {} } 1 .. 3;

    weaken $_ for my @weakrefs = @refs;

    @gots = extract_by { !defined $_ } @weakrefs;
    is_deeply(\@gots, [], 'extract undef refs returns nothing yet');
    is( scalar @weakrefs, 3, 'extract undef refs leaves array unchanged');
    ok(isweak $weakrefs[0], "extract_by doesn't break weakrefs");

    undef $refs[0];

    is_deeply( [ extract_by { !defined $_ } @weakrefs ], [ undef ], 'extract undef refs yields an undef' );
    is( scalar @weakrefs, 2,                                        'extract undef refs removes from array' );
    ok( isweak $weakrefs[0], "extract_by still doesn't break weakrefs" );
}

done_testing;
