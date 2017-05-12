use strict;
use warnings;
use Test::More tests => 2;
use Try::Tiny qw( try catch );

use INI::ReadPath;

my @cases = (
    {
        subject => "broken json",
        string  => 'LLLLLLLLLLLOOOOOO',
        path    => 'something',
        expected_error => qr/Syntax error at line 1: 'LLLLLLLLLLLOOOOOO/,
    },
    {
        subject => "parse json",
        string  => "author = Michael Vu\n",
        path    => 'ini.author',
        expected_value => "Michael Vu",
    },
);

foreach my $case( @cases ) {
    try {
        my $reader = INI::ReadPath->new( string => $case->{string} );
        $DB::single=2;
        my $got    = $reader->get( $case->{path} );
        is_deeply $got, $case->{expected_value}, $case->{subject};
    }
    catch {
        my $error = $_;
        like $error, $case->{expected_error}, $case->{subject};
    };
}
