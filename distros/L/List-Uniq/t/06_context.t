use strict;
use warnings;

BEGIN {
    use Test::More;
    our $tests = 4;
    eval "use Test::NoWarnings";
    $tests++ unless ($@);
    plan tests => $tests;
}

use_ok( 'List::Uniq', ':all' );

# make sure we get back lists or list references
my @in = qw|foo bar baz quux gzonk bar quux|;

# list context
my @ret     = uniq(@in);
my $retsize = @ret;
is $retsize, 5, 'call uniq in list context';

# scalar context
my $ret = uniq(@in);
is ref $ret, 'ARRAY', 'call uniq in scalar context';
is scalar @$ret, $retsize, 'size of returned lists match';
