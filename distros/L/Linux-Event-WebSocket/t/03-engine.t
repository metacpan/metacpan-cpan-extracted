use v5.36;
use strict;
use warnings;

use Test::More;
use Encode qw(encode);

use Linux::Event::WebSocket::_Engine;
use Linux::Event::WebSocket::_Frame;
use Linux::Event::WebSocket::_Parser;

{
    package T::Connection;

    sub new ($class) {
        return bless {
            output   => [],
            messages => [],
            closes   => [],
            errors   => [],
            closing  => 0,
            ended    => 0,
            closed   => 0,
        }, $class;
    }

    sub write ($self, $bytes) {
        push @{$self->{output}}, $bytes;
        return length $bytes;
    }

    sub end ($self) { ++$self->{ended}; return $self }
    sub is_write_ended ($self) { 0 }
    sub is_closed ($self) { !!$self->{closed} }

    sub _websocket_engine_message ($self, $payload, $type) {
        push @{$self->{messages}}, [ $type, $payload ];
        $self->{closed} = 1 if $self->{close_on_message};
        return;
    }

    sub _websocket_engine_close ($self, $code, $reason) {
        push @{$self->{closes}}, [ $code, $reason ];
        return;
    }

    sub _websocket_engine_error ($self, $error) {
        push @{$self->{errors}}, $error;
        return;
    }

    sub _websocket_engine_closing ($self) {
        $self->{closing} = 1;
        return;
    }
}

sub client_frame ($type, $payload, %option) {
    return Linux::Event::WebSocket::_Frame->encode(
        $type,
        $payload,
        masked   => 1,
        mask_key => "\x01\x02\x03\x04",
        %option,
    );
}

sub server_engine ($limit = 1024) {
    my $connection = T::Connection->new;
    my $engine = Linux::Event::WebSocket::_Engine->new(
        connection       => $connection,
        endpoint_type    => 'server',
        max_message_size => $limit,
    );
    return ($engine, $connection);
}

{
    my ($engine, $connection) = server_engine();
    $engine->send_binary('abc');
    is(
        $connection->{output}[0],
        Linux::Event::WebSocket::_Frame->encode('binary', 'abc'),
        'server engine fast path sends an ordinary binary frame',
    );
}

sub output_close_code ($wire) {
    my $parser = Linux::Event::WebSocket::_Parser->new(
        endpoint_type  => 'client',
        max_frame_size => 1024,
    );
    $parser->feed($wire);
    my $frame = $parser->next_frame;
    my ($code) = Linux::Event::WebSocket::_Frame->parse_close_payload(
        $frame->{payload},
    );
    return $code;
}

{
    my ($engine, $connection) = server_engine();
    $engine->feed(client_frame('text', 'hello'));
    is_deeply($connection->{messages}, [ [ text => 'hello' ] ],
        'engine delivers an unfragmented text message');
    is_deeply($connection->{errors}, [], 'valid text reports no error');
}

{
    my ($engine, $connection) = server_engine();
    my $wire = client_frame('text', 'hel', fin => 0)
        . client_frame('ping', 'p')
        . client_frame('continuation', 'lo');
    $engine->feed($wire);

    is_deeply($connection->{messages}, [ [ text => 'hello' ] ],
        'engine reassembles fragments around a control frame');
    is($connection->{output}[0],
        Linux::Event::WebSocket::_Frame->encode('pong', 'p'),
        'engine replies to ping with an identical pong payload');
}

{
    my ($engine, $connection) = server_engine();
    $connection->{close_on_message} = 1;
    $engine->feed(
        client_frame('text', 'first')
        . client_frame('text', 'second')
    );
    is_deeply($connection->{messages}, [ [ text => 'first' ] ],
        'engine stops a coalesced batch when a message callback closes transport');
}

{
    my ($engine, $connection) = server_engine(5);
    $engine->feed(client_frame('ping', '123456'));
    is_deeply($connection->{errors}, [],
        'control frames are independent of the application message limit');
    is($connection->{output}[0],
        Linux::Event::WebSocket::_Frame->encode('pong', '123456'),
        'valid ping above a small message limit still receives a pong');
}

{
    my ($engine, $connection) = server_engine();
    $engine->feed(client_frame('continuation', 'orphan'));
    like($connection->{errors}[0], qr/continuation/i,
        'orphan continuation reports a protocol error');
    is(output_close_code($connection->{output}[0]), 1002,
        'fragmentation protocol failure sends close 1002');
    ok($connection->{ended}, 'protocol failure ends transport output');
}

{
    my ($engine, $connection) = server_engine();
    $engine->feed(
        client_frame('text', 'unfinished', fin => 0)
        . client_frame('binary', 'new message')
    );
    like($connection->{errors}[0], qr/fragmented message is unfinished/,
        'new data frame during fragmentation reports a protocol error');
    is(output_close_code($connection->{output}[0]), 1002,
        'overlapping fragmented message sends close 1002');
}

{
    my ($engine, $connection) = server_engine(5);
    $engine->feed(
        client_frame('binary', 'abc', fin => 0)
        . client_frame('continuation', 'def')
    );
    like($connection->{errors}[0], qr/exceeds configured limit/,
        'fragmented message limit reports an error');
    is(output_close_code($connection->{output}[0]), 1009,
        'message-size failure sends close 1009');
}

{
    my ($engine, $connection) = server_engine();
    $engine->feed(client_frame('text', "\xff"));
    like($connection->{errors}[0], qr/UTF-8/,
        'invalid text reports a payload error');
    is(output_close_code($connection->{output}[0]), 1007,
        'invalid UTF-8 sends close 1007');
}

{
    my %valid = (
        two_byte     => [ 'c280',     0x80 ],
        nonchar_fffe => [ 'efbfbe',   0xfffe ],
        four_byte    => [ 'f0908080', 0x10000 ],
        max_scalar   => [ 'f48fbfbf', 0x10ffff ],
    );

    for my $name (sort keys %valid) {
        my ($hex, $codepoint) = @{$valid{$name}};
        my ($engine, $connection) = server_engine();
        $engine->feed(client_frame('text', pack('H*', $hex)));
        is_deeply($connection->{errors}, [],
            "$name passes Perl C API RFC 3629 validation");
        is(ord($connection->{messages}[0][1]), $codepoint,
            "$name is delivered as the expected Perl character");
    }
}

{
    my %invalid = (
        lone_continuation => '80',
        overlong_nul      => 'c080',
        overlong_three    => 'e08080',
        surrogate         => 'eda080',
        overlong_four     => 'f0808080',
        above_unicode     => 'f4908080',
        truncated         => 'f09080',
        illegal_lead      => 'f5',
    );

    for my $name (sort keys %invalid) {
        my ($engine, $connection) = server_engine();
        $engine->feed(client_frame('text', pack('H*', $invalid{$name})));
        like($connection->{errors}[0], qr/UTF-8/,
            "$name is rejected by Perl C API RFC 3629 validation");
        is(output_close_code($connection->{output}[0]), 1007,
            "$name sends close 1007");
    }
}

{
    my ($engine, $connection) = server_engine();
    my $payload = Linux::Event::WebSocket::_Frame->close_payload(1000, 'done');
    $engine->feed(client_frame('close', $payload));
    is_deeply($connection->{closes}, [ [ 1000, 'done' ] ],
        'peer close code and reason are delivered');
    is($connection->{output}[0],
        Linux::Event::WebSocket::_Frame->encode('close', $payload),
        'peer close is echoed by the server');
    ok($connection->{closing}, 'peer close marks the connection closing');
    ok($connection->{ended}, 'completed close handshake ends output');
}

{
    my ($engine, $connection) = server_engine();
    $engine->feed(client_frame('close', "\x03"));
    like($connection->{errors}[0], qr/one-byte payload/,
        'invalid close payload reports a protocol error');
    is(output_close_code($connection->{output}[0]), 1002,
        'invalid close payload sends close 1002');
    is($engine->{native}->_memory_used, 0,
        'rejected one-byte close leaves no native heap allocation');
}

{
    my ($engine, $connection) = server_engine();
    $engine->feed(client_frame('close', pack('n', 1005)));
    like($connection->{errors}[0], qr/invalid status code/,
        'reserved close status reports a protocol error');
    is(output_close_code($connection->{output}[0]), 1002,
        'reserved close status sends close 1002');
    is($engine->{native}->_memory_used, 0,
        'rejected reserved-status close leaves no native heap allocation');
}

{
    my ($engine, $connection) = server_engine();
    $engine->feed(client_frame('close', pack('n', 1000) . "\xff"));
    like($connection->{errors}[0], qr/UTF-8 reason/,
        'invalid close reason reports a payload error');
    is(output_close_code($connection->{output}[0]), 1007,
        'invalid close reason sends close 1007');
    is($engine->{native}->_memory_used, 0,
        'rejected invalid-UTF8 close leaves no native heap allocation');
}

{
    my ($engine, $connection) = server_engine();
    my $ok = eval { $engine->ping('x' x 126); 1 };
    ok(!$ok, 'outgoing ping larger than 125 bytes is rejected');
    like($@, qr/control frame payload exceeds 125 bytes/,
        'oversized outgoing ping reports the control-frame limit');
}

{
    my $connection = T::Connection->new;
    my $engine = Linux::Event::WebSocket::_Engine->new(
        connection       => $connection,
        endpoint_type    => 'client',
        max_message_size => 1024,
    );
    $engine->send_text(encode('UTF-8', "wide-\x{263a}"));

    my $parser = Linux::Event::WebSocket::_Parser->new(
        endpoint_type  => 'server',
        max_frame_size => 1024,
    );
    $parser->feed($connection->{output}[0]);
    my $frame = $parser->next_frame;
    is($frame->{opcode}, 1, 'client engine sends a text opcode');
    is($frame->{payload}, encode('UTF-8', "wide-\x{263a}"),
        'client engine sends UTF-8 bytes');
}

{
    my $connection = T::Connection->new;
    my $engine = Linux::Event::WebSocket::_Engine->new(
        connection       => $connection,
        endpoint_type    => 'client',
        max_message_size => 1024,
    );
    $engine->send_text("wide-\x{263a}");

    my $parser = Linux::Event::WebSocket::_Parser->new(
        endpoint_type  => 'server',
        max_frame_size => 1024,
    );
    $parser->feed($connection->{output}[0]);
    my $frame = $parser->next_frame;
    is($frame->{payload}, encode('UTF-8', "wide-\x{263a}"),
        'native send_text encodes a Perl Unicode scalar');
}

{
    for my $payload (
        "\xff",
        chr(0xd800),
        chr(0x110000),
    ) {
        my $connection = T::Connection->new;
        my $engine = Linux::Event::WebSocket::_Engine->new(
            connection       => $connection,
            endpoint_type    => 'server',
            max_message_size => 1024,
        );
        my $ok = eval { $engine->send_text($payload); 1 };
        ok(!$ok, 'native send_text rejects invalid RFC 3629 text');
        like($@, qr/invalid UTF-8/,
            'native send_text reports invalid UTF-8');
    }
}

done_testing;
