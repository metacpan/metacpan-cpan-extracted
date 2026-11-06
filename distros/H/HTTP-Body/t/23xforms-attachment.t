#!perl

use strict;
use warnings;

use Test::More tests => 5;

use HTTP::Body;
use File::Temp qw/ tempdir /;

# A multipart/related part other than the start part is an upload named after
# its Content-ID.  XFormsMultipart used to set its name before the MultiPart
# handler ran, which skipped both the NUL strip of the filename (RT#123615)
# and the creation of the temporary file, so the attachment was dropped.
my $raw = qq{--x\r\nContent-ID: <model>\r\nContent-Type: application/xml\r\n\r\n<m/>\r\n}
    . qq{--x\r\nContent-ID: <att\0ach>\r\nContent-Type: text/plain\r\n\r\nATTACHMENT DATA\r\n--x--\r\n};

my $body = HTTP::Body->new( 'multipart/related; boundary=x; start="<model>"', length $raw );
$body->tmpdir( tempdir( CLEANUP => 1 ) );
$body->cleanup(1);
$body->add($raw);

is( $body->param->{'XForms:Model'}, '<m/>', 'the start part is the model' );

my ($upload) = values %{ $body->upload };
is( $upload->{filename}, 'attach', 'NUL is stripped from the attachment filename' );
is( $upload->{name},     'attach', '... and from its name' );
ok( $upload->{tempname} && -e $upload->{tempname}, 'the attachment is written to a temporary file' );

my $data = '';
if ( $upload->{tempname} && open my $fh, '<', $upload->{tempname} ) {
    local $/;
    $data = <$fh>;
}
is( $data, 'ATTACHMENT DATA', 'the temporary file holds the attachment data' );
