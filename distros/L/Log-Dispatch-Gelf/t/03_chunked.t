use strict;
use warnings;

use Test::More;

use Log::Dispatch;
use Log::GELF::Util qw(dechunk decode_chunk uncompress);
use JSON;
use Test::Exception;
use Mock::Quick;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

my @ACCUMULATOR;
my $MESSAGE;
my $class_inet = qclass(
    -implement => 'IO::Socket::INET',
    new        => sub {
        my ($obj, %options) = @_;
        @ACCUMULATOR = undef;
        $MESSAGE     = undef;
        return bless {}, $obj;
    },
    send => sub {
        my ($self, $encoded_chunk) = @_;
        
        $MESSAGE = dechunk(
            \@ACCUMULATOR,
            decode_chunk($encoded_chunk)
        );

        $MESSAGE = uncompress($MESSAGE) if $MESSAGE;

    }
);

throws_ok {
    Log::Dispatch->new(
        outputs => [
            [
                'Gelf',
                min_level => 'debug',
                chunked  => 'WAN',
                'socket'  => {
                    host     => 'test',
                    protocol => 'tcp',
                }
            ]
        ],
    );
}
qr/chunked only applicable to udp/, 'invalid protocol for chunking';

throws_ok {
    Log::Dispatch->new(
        outputs => [
            [
                'Gelf',
                min_level => 'debug',
                chunked   => 'xxx',
                'socket'  => {
                    host     => 'test',
                    protocol => 'udp',
                }
            ]
        ],
    );
}
qr/chunk size must be "lan", "wan", a positve integer, or 0 \(no chunking\)/, 'invalid chunked value';

throws_ok {
    Log::Dispatch->new(
        outputs => [
            [
                'Gelf',
                min_level => 'debug',
                chunked   => '-1',
                'socket'  => {
                    host     => 'test',
                    protocol => 'udp',
                }
            ]
        ],
    );
}
qr/chunk size must be "lan", "wan", a positve integer, or 0 \(no chunking\)/, 'invalid integer';

new_ok ( 'Log::Dispatch', [
        outputs => [
            [
                'Gelf',
                min_level => 'debug',
                chunked  => 'WAN',
                socket    => {
                    host => 'test',
                }
            ]
        ]
    ]
);

new_ok ( 'Log::Dispatch', [
        outputs => [
            [
                'Gelf',
                min_level => 'debug',
                chunked  => 'lan',
                socket    => {
                    host => 'test',
                }
            ]
        ]
    ]
);

new_ok ( 'Log::Dispatch', [
        outputs => [
            [
                'Gelf',
                min_level => 'debug',
                'socket'  => {
                    host     => 'test',
                    protocol => 'tcp',
                }
            ]
        ]
    ]
);

my $log = Log::Dispatch->new(
    outputs => [
        [
            'Gelf',
            min_level => 'debug',
            chunked  => 4,
            socket    => {
                host => 'test',
            }
        ]
    ],
);

$log->info("Uncompressed - chunked\nMore details.");

note("formatted message: $MESSAGE");

my $msg = decode_json($MESSAGE);

is($msg->{level},         6,                                       'correct level info');
is($msg->{short_message}, 'Uncompressed - chunked',                'short_message correct');
is($msg->{full_message},  "Uncompressed - chunked\nMore details.", 'full_message correct');

$log = Log::Dispatch->new(
    outputs => [
        [
            'Gelf',
            min_level  => 'debug',
            compress => 1,
            chunked  => 4,
            socket    => {
                host => 'test',
            }
        ]
    ],
);

$log->info("Compressed - chunked\nMore details.");

note("formatted message: $MESSAGE");

$msg = decode_json($MESSAGE);

is($msg->{level},         6,                                     'correct level info');
is($msg->{short_message}, 'Compressed - chunked',                'short_message correct');
is($msg->{full_message},  "Compressed - chunked\nMore details.", 'full_message correct');

done_testing(12);
