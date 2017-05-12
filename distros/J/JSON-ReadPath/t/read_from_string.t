use strict;
use warnings;
use Test::More tests => 2;
use Try::Tiny qw( try catch );

use JSON::ReadPath;

my @cases = (
    {
        subject => "broken json",
        string  => '{..BROKEN..}',
        path    => 'something',
        expected_error => qr/'"' expected, at character offset 1/,
    },
    {
        subject => "parse json",
        string  => '{"commits": { "repo": "Foobar" }}',
        path    => 'commits.repo',
        expected_value => "Foobar",
    },
);

foreach my $case( @cases ) {
    try {
        my $reader = JSON::ReadPath->new( string => $case->{string} );
        my $got    = $reader->get( $case->{path} );
        is_deeply $got, $case->{expected_value}, $case->{subject};
    }
    catch {
        my $error = $_;
        like $error, $case->{expected_error}, $case->{subject};
    };
}
