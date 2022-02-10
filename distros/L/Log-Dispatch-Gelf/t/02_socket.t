use strict;
use warnings;

use Test::More;

use Log::Dispatch;
use JSON::MaybeXS;
use Test::Exception;
use Mock::Quick;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

throws_ok {
    Log::Dispatch->new(
        outputs => [
            [
                'Gelf', min_level => 'debug',
            ]
        ],
    );
}
qr/^Must be set socket or send_sub/, 'empty socket';

throws_ok {
    Log::Dispatch->new(
        outputs => [
            [
                'Gelf',
                min_level => 'debug',
                'socket'  => {}
            ]
        ],
    );
}
qr/socket host must be set/, 'undefined socket host';

throws_ok {
    Log::Dispatch->new(
        outputs => [
            [
                'Gelf',
                min_level => 'debug',
                'socket'  => {
                    host => ''
                }
            ]
        ],
    );
}
qr/socket host must be set/, 'empty socket host';

throws_ok {
    Log::Dispatch->new(
        outputs => [
            [
                'Gelf',
                min_level => 'debug',
                'socket'  => {
                    host => 'test',
                    port => 'x',
                }
            ]
        ],
    );
}
qr/socket port must be integer/, 'invalid socket port';

throws_ok {
    Log::Dispatch->new(
        outputs => [
            [
                'Gelf',
                min_level => 'debug',
                'socket'  => {
                    host     => 'test',
                    port     => '111111',
                    protocol => 'invalid',
                }
            ]
        ],
    );
}
qr/socket protocol must be tcp or udp/, 'invalid protocol';

throws_ok {
    Log::Dispatch->new(
        outputs => [
            [
                'Gelf',
                min_level => 'debug',
                'socket'  => {
                    host     => 'test',
                    port     => '111111',
                    protocol => 'xxx-udp',
                }
            ]
        ],
    );
}
qr/socket protocol must be tcp or udp/, 'invalid protocol 2';

my $LAST_LOG_MSG;
my $validate_constructor_options;
my $class_inet = qclass(
    -implement => 'IO::Socket::INET',
    new        => sub {
        my ($obj, %options) = @_;

        if ($validate_constructor_options) {
            is_deeply(\%options, $validate_constructor_options, 'connect opts');
        }

        return bless {}, $obj;
    },
    send => sub {
        my ($self, $msg) = @_;

        $LAST_LOG_MSG = $msg;
    }
);

$validate_constructor_options = { PeerAddr => 'test', PeerPort => 12201, Proto => 'udp' };
my $log = Log::Dispatch->new(
    outputs => [
        [
            'Gelf',
            min_level => 'debug',
            socket    => {
                host => 'test',
            }
        ]
    ],
);

$log->info("It works\nMore details.");

note("formatted message: $LAST_LOG_MSG");

my $msg = decode_json($LAST_LOG_MSG);
is($msg->{level},         6,                         'correct level info');
is($msg->{short_message}, 'It works',                'short_message correct');
is($msg->{full_message},  "It works\nMore details.", 'full_message correct');

$log = Log::Dispatch->new(
    outputs => [
        [
            'Gelf',
            min_level => 'debug',
            compress => 1,
            socket    => {
                host => 'test',
            }
        ]
    ],
);

$log->info("Compressed\nMore details.");

my $output;
gunzip \$LAST_LOG_MSG => \$output
    or die "gunzip failed: $GunzipError\n";

note("formatted message: $output");

$msg = decode_json($output);
is($msg->{level},         6,                           'correct level info');
is($msg->{short_message}, 'Compressed',                'short_message correct');
is($msg->{full_message},  "Compressed\nMore details.", 'full_message correct');

$validate_constructor_options = undef;

$log = Log::Dispatch->new(
    outputs => [ [
        'Gelf',
        min_level         => 'debug',
        socket            => {
            host     => 'graylog.server',
            port     => 21234,
            protocol => 'tcp',
        }
    ] ],
);
$log->log(
    level   => 'info',
    message => "It works\nMore details.",
);
ok(substr($LAST_LOG_MSG, -1) eq "\x00", 'TCP transport ends with a null byte');
note("formatted message: $LAST_LOG_MSG");
substr($LAST_LOG_MSG, -1) = '';
$msg = decode_json($LAST_LOG_MSG);
is($msg->{level},         6,                         'correct level info');
is($msg->{short_message}, 'It works',                'short_message correct');
is($msg->{full_message},  "It works\nMore details.", 'full_message correct');

done_testing(18);
