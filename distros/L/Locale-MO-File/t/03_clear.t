#!perl -T

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    require_ok 'Locale::MO::File';
}

lives_ok
    sub {
        my $mo = Locale::MO::File->new;
        $mo->clear_filename;
        $mo->clear_file_handle;
        $mo->clear_encoding;
        $mo->clear_newline;
        $mo->clear_is_big_endian;
    },
    'check clearer';
