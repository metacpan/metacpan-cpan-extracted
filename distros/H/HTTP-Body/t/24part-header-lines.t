#!perl

use strict;
use warnings;

use Test::More tests => 4;

use HTTP::Body;

my $ct = 'multipart/form-data; boundary=x';

{
    # A continuation line with no header line before it died in parse_header
    # with "Modification of non-creatable array value attempted".
    my $raw  = qq{--x\r\n junk\r\nContent-Disposition: form-data; name="a"\r\n\r\nv\r\n--x--\r\n};
    my $body = HTTP::Body->new( $ct, length $raw );
    my $ok   = eval { $body->add($raw); 1 };
    ok( $ok, 'a part header block that starts with whitespace does not die' ) or diag $@;
    is( $body->param->{a}, 'v', '... and the part is parsed' );
}

{
    # A line that is no header field was stored under whatever $1 was left
    # over from the last successful match.
    my $raw  = qq{--x\r\nContent-Disposition: form-data; name="a"\r\nthis is not a header\r\n\r\nv\r\n--x--\r\n};
    my $body = HTTP::Body->new( $ct, length $raw );
    $body->add($raw);
    is( $body->param->{a}, 'v', 'a part with a line that is no header field is parsed' );
    is_deeply(
        [ sort keys %{ $body->part_data->{a}{headers} } ],
        ['Content-Disposition'],
        'the line is not stored under a made-up field name'
    );
}
