#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML;

# The arena and the output buffer, through the private selftest: pointer
# stability across pages, the oversize page, a NUL-terminated string, the
# buffer's doubling, and a free that leaves nothing behind.
is(File::Raw::XML::_arena_selftest(), 1, 'the arena and buffer selftest passes');

# The one refusal message shape, on a buffer a %s would have mangled.
my $in  = "ab\0cd\xff\"\\<x> tail beyond sixteen bytes";
my $msg = File::Raw::XML::_err_format('something', 2, $in);

like($msg, qr/^File::Raw::XML: something at byte offset 2 near "/,
     'prefix, what, and the offset');
like($msg, qr/\\x00/, 'the NUL is rendered \\x00');
like($msg, qr/\\xff/, 'the high byte is rendered \\xff');
like($msg, qr/\\x22/, 'the quote is rendered \\x22');
like($msg, qr/\\x5c/, 'the backslash is rendered \\x5c');
unlike($msg, qr/\0/, 'and no raw NUL survives into the message');
like($msg, qr/"\z/, 'the context closes its quote');

# Sixteen bytes of context, counted on the input, not on the rendering.
my ($ctx) = $msg =~ /near "(.*)"\z/;
(my $plain = $ctx) =~ s/\\x[0-9a-f]{2}/./g;
is(length $plain, 16, 'sixteen input bytes of context');

is(File::Raw::XML::_err_format('eof', 99, $in),
   'File::Raw::XML: eof at end of input',
   'an offset past the end says so instead of quoting nothing');

is(File::Raw::XML::_err_format('eof', 0, ''),
   'File::Raw::XML: eof at end of input',
   'and so does an empty input');

done_testing;
