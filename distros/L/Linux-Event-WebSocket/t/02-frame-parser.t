use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::WebSocket::_Frame;
use Linux::Event::WebSocket::_Parser;

sub dies_like ($code, $pattern, $name) {
    my $ok = eval { $code->(); 1 };
    my $error = $@;
    ok(!$ok, $name);
    like($error, $pattern, "$name reports expected error");
}

my $masked_hello = pack('H*', '818537fa213d7f9f4d5158');
is(
    Linux::Event::WebSocket::_Frame->encode(
        'text',
        'Hello',
        masked   => 1,
        mask_key => pack('H*', '37fa213d'),
    ),
    $masked_hello,
    'encoder matches the RFC masked Hello vector',
);
is(
    Linux::Event::WebSocket::_Frame->encode('text', 'Hello'),
    "\x81\x05Hello",
    'encoder creates an unmasked server text frame',
);

my $server_parser = Linux::Event::WebSocket::_Parser->new(
    endpoint_type  => 'server',
    max_frame_size => 1024,
);
$server_parser->feed($masked_hello);
is_deeply(
    $server_parser->next_frame,
    { fin => 1, opcode => 1, type => 'text', payload => 'Hello' },
    'server parser decodes a masked client frame',
);
is($server_parser->next_frame, undef, 'parser reports incomplete input');

my $wire126 = Linux::Event::WebSocket::_Frame->encode(
    'binary',
    'x' x 126,
    masked   => 1,
    mask_key => "\x01\x02\x03\x04",
);
is(ord(substr($wire126, 1, 1)) & 0x7f, 126,
    'encoder uses the 16-bit length form at 126 bytes');

for my $split (1 .. length($wire126) - 1) {
    my $parser = Linux::Event::WebSocket::_Parser->new(
        endpoint_type  => 'server',
        max_frame_size => 1024,
    );
    $parser->feed(substr($wire126, 0, $split));
    is($parser->next_frame, undef, "frame is incomplete at split $split");
    $parser->feed(substr($wire126, $split));
    my $frame = $parser->next_frame;
    is($frame->{payload}, 'x' x 126, "frame completes after split $split");
}

my $client_parser = Linux::Event::WebSocket::_Parser->new(
    endpoint_type  => 'client',
    max_frame_size => 1024,
);
$client_parser->feed("\x81\x01a\x82\x01b");
is($client_parser->next_frame->{payload}, 'a',
    'parser returns the first coalesced frame');
is($client_parser->next_frame->{payload}, 'b',
    'parser returns the second coalesced frame');

dies_like(
    sub {
        my $parser = Linux::Event::WebSocket::_Parser->new(
            endpoint_type => 'server', max_frame_size => 1024,
        );
        $parser->feed("\x81\x01x");
        $parser->next_frame;
    },
    qr/client frame is not masked/,
    'server rejects an unmasked client frame',
);

dies_like(
    sub {
        my $parser = Linux::Event::WebSocket::_Parser->new(
            endpoint_type => 'client', max_frame_size => 1024,
        );
        $parser->feed($masked_hello);
        $parser->next_frame;
    },
    qr/server frame is masked/,
    'client rejects a masked server frame',
);

for my $case (
    [ "\xc1\x00", qr/reserved bits/, 'RSV bits' ],
    [ "\x83\x00", qr/opcode/, 'reserved opcode' ],
    [ "\x09\x00", qr/control frame is fragmented/, 'fragmented control frame' ],
    [ "\x89\x7e\x00\x7e", qr/control frame payload exceeds 125/, 'long control frame' ],
    [ "\x82\x7e\x00\x7d", qr/non-minimal/, 'non-minimal 16-bit length' ],
    [ "\x82\x7f\x00\x00\x00\x00\x00\x00\xff\xff", qr/non-minimal/,
        'non-minimal 64-bit length' ],
    [ "\x82\x7f\x80\x00\x00\x00\x00\x00\x00\x00", qr/most significant bit/,
        '64-bit high bit' ],
    [ "\x82\x7e\x04\x01", qr/exceeds configured limit/, 'advertised size limit' ],
) {
    my ($wire, $pattern, $name) = @$case;
    dies_like(
        sub {
            my $parser = Linux::Event::WebSocket::_Parser->new(
                endpoint_type  => 'client',
                max_frame_size => 1024,
            );
            $parser->feed($wire);
            $parser->next_frame;
        },
        $pattern,
        "parser rejects $name",
    );
}

done_testing;
