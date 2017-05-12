#!perl

use strict;
use warnings;
use Test::More tests => 3;

use List::Util qw/max sum/;

use File::Temp qw/tempfile/;

BEGIN {
    use_ok('File::SimpleQuery');
}

my ($fh, $filename) = tempfile();
print $fh (join "\n", map { join ",",  @$_ } _random_data());
close $fh;


my $q = File::SimpleQuery->new($filename, ',');

my @results = $q->select(
    [ qw/ first second / ],
    sub {1},
    []
);

is_deeply(
    \@results,
    [
        {
            first => 1,
            second => 2,
        },
        {
            first => 6,
            second => 7,
        },
        {
            first => 11,
            second => 12,
        },
    ],
    'simple SimpleQuery is correct',
);

@results = $q->select(
    [ qw/ first second / ],
    sub { my ($fields) = @_; return $fields->{first} > 1 && $fields->{second} < 12 },
    []
);

is_deeply(
    \@results,
    [
        {
            first => 6,
            second => 7,
        },
    ],
    'simple SimpleQuery with simple where_sub is correct'
);





sub _random_data
{
    return (
        [ qw/first second third fourth fifth/ ],
        [ 1 .. 5 ],
        [ 6 .. 10 ],
        [ 11 .. 15 ],
    );
}
