#!perl

use strict;
use warnings;

use Test::More tests => 5;

use HTTP::Body;
use File::Temp qw/ tempdir /;
use Time::HiRes qw/ time /;

my $ct = 'multipart/form-data; boundary=x';

# A filename of many dots that ends in a backslash made the default
# $basename_regexp backtrack in time quadratic in the filename's length:
# about 7 seconds for a part whose header block fills the 32 KiB limit,
# and that once per part, up to $max_parts times per body.
my $hostile = ( 'a.' x 16000 ) . 'a\\';
my $part    = qq{--x\r\nContent-Disposition: form-data; name="f"; filename="$hostile"\r\n\r\nD\r\n};

sub parse {
    my $raw  = shift;
    my $body = HTTP::Body->new( $ct, length $raw );
    $body->tmpdir( tempdir( CLEANUP => 1 ) );
    $body->cleanup(1);
    $body->add($raw);
    return $body;
}

{
    my $t    = time;
    my $body = parse( ( $part x 2 ) . "--x--\r\n" );
    cmp_ok( time - $t, '<', 5, 'hostile filename is handled in linear time with the fixed suffix' );
    is( $body->state, 'done', 'body with hostile filenames is parsed' );
}

{
    local $HTTP::Body::MultiPart::file_temp_suffix = undef;
    my $t    = time;
    my $body = parse( ( $part x 2 ) . "--x--\r\n" );
    cmp_ok( time - $t, '<', 5, 'hostile filename is handled in linear time with the suffix taken from the filename' );
    is( $body->state, 'done', 'body with hostile filenames is parsed in that mode too' );
}

{
    # The suffix is taken from the end of the filename, so a long name keeps it.
    local $HTTP::Body::MultiPart::file_temp_suffix = undef;
    my $long = ( 'n' x 300 ) . '.txt';
    my $body = parse( qq{--x\r\nContent-Disposition: form-data; name="f"; filename="$long"\r\n\r\nD\r\n--x--\r\n} );
    like( $body->upload->{f}{tempname}, qr/\.txt$/, 'suffix of a filename longer than 255 bytes is kept' );
}
