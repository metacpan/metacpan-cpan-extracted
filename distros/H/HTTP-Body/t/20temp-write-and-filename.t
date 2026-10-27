#!perl

use strict;
use warnings;

use Test::More tests => 4;

use HTTP::Body;
use File::Temp qw/ tempfile /;

# RT#123615: a NUL in the Content-Disposition filename is stripped, so it can
# not truncate a path handed on by the application.
{
    my $raw = qq{--x\r\n}
        . qq{Content-Disposition: form-data; name="f"; filename="a\0/etc/passwd"\r\n}
        . qq{\r\nDATA\r\n--x--\r\n};
    my $body = HTTP::Body->new( 'multipart/form-data; boundary=x', length $raw );
    $body->add($raw);
    my $upload = $body->upload->{f};
    unlike( $upload->{filename}, qr/\0/, 'NUL is stripped from the filename' );
    is( $upload->{filename}, 'a/etc/passwd', 'the rest of the filename is kept' );
}

# RT#105021: a failed write to the temporary file is reported, not ignored.
{
    my ( $fh, $filename ) = tempfile( UNLINK => 1 );
    close $fh;
    open my $readonly, '<', $filename or die "open: $!";

    my $body = HTTP::Body->new( 'application/octet-stream', 5 );
    $body->body($readonly);    # a sink that cannot be written to

    my $ok = eval { $body->add('hello'); 1 };
    ok( !$ok, 'a write error on the temporary file croaks' );
    like( $@, qr/Can't write to temporary file/, 'the croak names the cause' );
}
