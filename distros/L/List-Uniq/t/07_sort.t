use strict;
use warnings;

my $exceptions;

BEGIN {
    use Test::More;
    our $tests = 8;
    eval "use Test::NoWarnings";
    $tests++ unless ($@);
    eval "use Test::Exception";
    if ($@) {
        my $b = Test::Builder->new;
        $b->diag('Test::Exception not installed.  Not all tests will run');
    }
    else {
        $tests++;
        $exceptions = 1;
    }
    plan tests => $tests;
}

use_ok( 'List::Uniq', ':all' );

# default sort
my @in       = qw|foo bar baz quux gzonk bar quux|;
my @expected = qw|bar baz foo gzonk quux|;
my @ret      = uniq( { sort => 1 }, @in );
is_deeply \@ret, \@expected, 'default sort';

# explicit lexical sort
my $sort = sub { $_[0] cmp $_[1] };
@ret = uniq( { sort => 1, compare => $sort }, @in );
is_deeply \@ret, \@expected, 'explicit lexical sort';

# lexical case insensitive
@in       = qw|foo Bar baz Quux gzonk Bar Quux|;
$sort     = sub { uc( $_[0] ) cmp uc( $_[1] ) };
@expected = qw|Bar baz foo gzonk Quux|;
@ret      = uniq( { sort => 1, compare => $sort }, @in );
is_deeply \@ret, \@expected, 'case insensitive sort';

# lexical reverse
$sort     = sub { $_[1] cmp $_[0] };
@in       = qw|foo bar baz quux gzonk bar quux|;
@expected = qw|quux gzonk foo baz bar|;
@ret      = uniq( { sort => 1, compare => $sort }, @in );
is_deeply \@ret, \@expected, 'reversed sort';

# numbers with default sort
@in       = qw|1 2 3 4 5 6 7 8 9 10 11 12 11 10 9 8 7 6 5 4 3 2 1|;
@expected = qw|1 10 11 12 2 3 4 5 6 7 8 9|;
@ret      = uniq( { sort => 1 }, @in );
is_deeply \@ret, \@expected, 'default sort of numbers';

# numeric ascending
$sort     = sub { $_[0] <=> $_[1] };
@expected = qw|1 2 3 4 5 6 7 8 9 10 11 12|;
@ret      = uniq( { sort => 1, compare => $sort }, @in );
is_deeply \@ret, \@expected, 'numeric ascending sort';

# numeric descending
$sort     = sub { $_[1] <=> $_[0] };
@expected = qw|12 11 10 9 8 7 6 5 4 3 2 1|;
@ret      = uniq( { sort => 1, compare => $sort }, @in );
is_deeply \@ret, \@expected, 'numeric descending sort';

# make sure we throw an exception if we try to pass a non-CODEREF
# as a sort routine
if ($exceptions) {
    throws_ok {
        uniq( { sort => 1, compare => 1 }, @in );
    }
    qr/compare option is not a CODEREF/, 'pass non-CODEREF for custom sort';
}
