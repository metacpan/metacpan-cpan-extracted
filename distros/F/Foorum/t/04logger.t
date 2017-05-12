#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    $ENV{TEST_FOORUM} = 1;
}

use Test::More tests => 3;
use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use Foorum::SUtils qw/schema/;
use Foorum::Logger qw/%levels error_log/;
use Foorum::TestUtils qw/rollback_db/;

my $schema = schema();

is_deeply(
    \%levels,
    {   'info'  => 1,
        'debug' => 2,
        'warn'  => 3,
        'error' => 4,
        'fatal' => 5
    },
    'import \%levels OK'
);

error_log( $schema, 'info',  'info text' );
error_log( $schema, 'debug', 'debug text' );
error_log( $schema, 'warn',  'warn text' );
error_log( $schema, 'error', 'error text' );
error_log( $schema, 'fatal', 'fatal text' );

# get count
my $count = $schema->resultset('LogError')->count();
is( $count, 5, 'get 5 records' );
my $debug = $schema->resultset('LogError')->search( { level => 2, } )->first;
is( $debug->text, 'debug text', 'get debug text with level 2 OK' );

END {

    # Keep Database the same from original
    rollback_db();
}
