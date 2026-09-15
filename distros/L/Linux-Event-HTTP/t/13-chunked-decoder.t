use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::HTTP::_HTTP1;

my $decoder = Linux::Event::HTTP::_HTTP1::Chunked->new;

my $wire = "4\r";
my ($done, $decoded) = $decoder->feed($wire, 1);
ok(!$done, 'fragmented chunk header is incomplete');
ok(!defined $decoded, 'fragmented chunk header emits no body bytes');
is($wire, '', 'incomplete chunk input is consumed into decoder state');

$wire = "\nWiki\r\n5\r\nped";
($done, $decoded) = $decoder->feed($wire, 1);
ok(!$done, 'decoder remains incomplete across chunk boundary');
is($decoded, 'Wikiped', 'decoder emits available body bytes across chunks');
is($wire, '', 'second incomplete input is fully consumed');

$wire = "ia\r\n0\r\nX-Trailer: yes\r\n\r\nNEXT";
($done, $decoded) = $decoder->feed($wire, 1);
ok($done, 'zero chunk and trailers complete the body');
is($decoded, 'ia', 'final decoded body bytes are emitted');
is($wire, 'NEXT', 'bytes after the chunked message remain for the next request');

my $discard = Linux::Event::HTTP::_HTTP1::Chunked->new;
$wire = "3\r\nabc\r\n0\r\n\r\nTAIL";
($done, $decoded) = $discard->feed($wire, 0);
ok($done, 'discard mode still reaches the chunked body boundary');
ok(!defined $decoded, 'discard mode avoids materializing decoded body bytes');
is($wire, 'TAIL', 'discard mode preserves following protocol bytes');

my $bad = Linux::Event::HTTP::_HTTP1::Chunked->new;
$wire = "Z\r\n";
my $ok = eval { $bad->feed($wire, 1); 1 };
ok(!$ok, 'malformed chunk size is rejected');
like($@, qr/malformed HTTP\/1 chunked request body/, 'chunked error is explicit');

done_testing;
