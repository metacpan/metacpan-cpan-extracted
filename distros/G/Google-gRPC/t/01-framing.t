use strict;
use warnings;
use Test::More tests => 3;
use Google::gRPC::Framing;

subtest 'pack and unpack single frame' => sub {
    my $payload = 'hello grpc world';
    my $packed = Google::gRPC::Framing::pack_frame($payload, compressed => 0);
    is(length($packed), 5 + length($payload), 'packed frame length is header + payload');

    my $buffer = $packed;
    my @frames = Google::gRPC::Framing::unpack_frame(\$buffer);
    is(scalar(@frames), 1, 'unpacked 1 frame');
    is($frames[0]->{compressed}, 0, 'compression flag is 0');
    is($frames[0]->{payload}, 'hello grpc world', 'payload matches');
    is($buffer, '', 'buffer is completely consumed');
};

subtest 'unpack multiple frames chunked' => sub {
    my $p1 = 'frame 1';
    my $p2 = 'frame 2 message long payload';
    my $packed = Google::gRPC::Framing::pack_frame($p1) . Google::gRPC::Framing::pack_frame($p2);

    my $buf = substr($packed, 0, 8);
    my @f1 = Google::gRPC::Framing::unpack_frame(\$buf);
    is(scalar(@f1), 0, 'incomplete frame returns nothing');

    $buf .= substr($packed, 8);
    my @f2 = Google::gRPC::Framing::unpack_frame(\$buf);
    is(scalar(@f2), 2, 'unpacked 2 frames');
    is($f2[0]->{payload}, $p1, 'first frame payload matches');
    is($f2[1]->{payload}, $p2, 'second frame payload matches');
};

subtest 'parse trailers' => sub {
    my $headers = {
        'content-type' => 'application/grpc',
        'grpc-status'  => '0',
        'grpc-message' => 'OK',
    };
    my $trailers = Google::gRPC::Framing::parse_trailers($headers);
    is($trailers->{status}, 0, 'grpc-status is 0');
    is($trailers->{message}, 'OK', 'grpc-message is OK');
};
