use strict;
use warnings;

use Test::More tests => 8;

# A part may carry several base64 streams in a row, each ended by its own '='
# padding.  Mainstream MUAs decode them one after the other; a decoder that
# drops the padding and runs the whole part together as a single stream turns
# everything past the first padding into garbage -- which is what malware uses
# to smuggle an archive past a scanner.  testmsgs/concatenated-base64.msg is
# such a message: a ZIP holding the EICAR test file, cut into one base64
# stream every two bytes.

use MIME::Parser;
use MIME::Decoder;
use MIME::Base64 qw(encode_base64);
use IO::File;

sub decode_base64_stream {
    my ($encoded) = @_;
    my $decoded = '';
    open(my $in,  '<', \$encoded) or die "in: $!";
    open(my $out, '>', \$decoded) or die "out: $!";
    MIME::Decoder->new('base64')->decode($in, $out);
    return $decoded;
}

my $parser = MIME::Parser->new();
$parser->output_to_core(1);        ### keep the payload out of the filesystem
my $entity = $parser->parse_open("testmsgs/concatenated-base64.msg");

is(scalar($entity->parts), 2, 'Entity has two parts');

my $zip = $entity->parts(1)->bodyhandle->as_string;
is(length($zip), 186, 'Attachment decodes to its full length');
is(substr($zip, 0, 4), "PK\x03\x04", 'Attachment decodes to a ZIP archive');
like($zip, qr/eicar\.com/, 'ZIP holds the expected member');

### One stream decodes as it always did:
is(decode_base64_stream(encode_base64("Hello, world!")),
   "Hello, world!", 'A single base64 stream still decodes');

### ...and so do several in a row:
is(decode_base64_stream(encode_base64("Hello, ") . encode_base64("world!")),
   "Hello, world!", 'Concatenated base64 streams decode as one payload');

### A '=' that cannot be a padding used to spin the decoder forever; these
### two return rather than hang:
is(decode_base64_stream("=A"), "", 'A stray padding decodes to nothing');
like(decode_base64_stream("SGVsbG8=3D=3D"), qr/\AHello/,
     'A quoted-printable encoded padding does not lose the payload');

1;
