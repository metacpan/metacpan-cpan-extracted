use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use IO::Socket::UNIX;

use lib 'lib';
use Mail::MIMEDefang::OpenSMTPD qw(
    split_addr relay_hostname encode_command mx_request
    parse_mx_reply reply_to_decision stuff_line unstuff_line tls_macros
);

# --- addresses -------------------------------------------------------------
is_deeply [ split_addr('192.0.2.1:2525') ], [ '192.0.2.1', 2525 ], 'ipv4';
is_deeply [ split_addr('[::1]:25') ],       [ '::1', 25 ],         'ipv6 with port';
is_deeply [ split_addr('[2001:db8::1]') ],  [ '2001:db8::1', 0 ],  'ipv6 no port';
is_deeply [ split_addr('local') ],          [ 'local', 0 ],        'local';
is_deeply [ split_addr(undef) ],            [ 'unknown', 0 ],      'undef';

is relay_hostname( 'mx.example.org', '192.0.2.1' ), 'mx.example.org', 'rdns kept';
is relay_hostname( undef,            '192.0.2.1' ), '[192.0.2.1]',    'no rdns';
is relay_hostname( '<unknown>',      '::1' ),       '[::1]',          'unknown rdns';

# --- commands --------------------------------------------------------------
is encode_command( 'relayok', '192.0.2.1', 'a b', '', undef, 25 ),
    'relayok 192.0.2.1 a%20b ? ? 25', 'arguments encoded, empty -> ?';

# --- replies ---------------------------------------------------------------
my $r = parse_mx_reply("ok 1 ok 250 2.1.0 0\n");
is $r->{status}, 1, 'continue';

$r = parse_mx_reply("ok 0 Go%20away 554 5.7.1 0\n");
is_deeply [ reply_to_decision( $r, 'x' ) ], [ 'reject', '554 5.7.1 Go away' ],
    'reject with custom text';

$r = parse_mx_reply("ok -1 Try%20later 451 4.3.0 0\n");
is_deeply [ reply_to_decision( $r, 'x' ) ], [ 'reject', '451 4.3.0 Try later' ],
    'tempfail';

$r = parse_mx_reply("ok 0 ? 250 2.1.0 0\n");
is_deeply [ reply_to_decision( $r, 'relay not allowed' ) ],
    [ 'reject', '550 5.7.1 relay not allowed' ],
    'bad code/dsn and empty message fall back to defaults';

is( ( reply_to_decision( parse_mx_reply("ok 2 ? 250 2.1.0 0") ) )[0], 'accept',  'ok 2' );
is( ( reply_to_decision( parse_mx_reply("ok 3 ? 250 2.1.0 0") ) )[0], 'discard', 'ok 3' );
is( ( reply_to_decision( undef, 'x' ) )[1], '451 4.3.0 Temporary failure, please try again later.',
    'no answer is a tempfail' );
is parse_mx_reply('error: boom'), undef, 'not an ok answer';

# --- dot stuffing ----------------------------------------------------------
is stuff_line('.hidden'), '..hidden', 'stuff';
is stuff_line('plain'),   'plain',    'stuff leaves other lines';
is unstuff_line('..x'),   '.x',       'unstuff';

# --- tls -------------------------------------------------------------------
is_deeply { tls_macros('TLSv1.3:AEAD-AES256-GCM-SHA384:256') },
    { tls_version => 'TLSv1.3', cipher => 'AEAD-AES256-GCM-SHA384', cipher_bits => 256 },
    'tls macros';
is_deeply { tls_macros(undef) }, {}, 'no tls';

# --- multiplexor round trip ------------------------------------------------
my $dir  = tempdir( CLEANUP => 1 );
my $path = "$dir/mx.sock";
my $srv  = IO::Socket::UNIX->new( Local => $path, Listen => 5 ) or die $!;
my $pid  = fork() // die;
if ( not $pid ) {
    my $n = 0;
    while ( my $c = $srv->accept ) {
        my $line = <$c>;
        $n++;
        if ( $line =~ /^bigreply/ ) {
            print {$c} 'x' x 5000, "\n";
        }
        elsif ( $line =~ /^silent/ ) {
            # close without answering
        }
        else {
            print {$c} "echo: $line";
        }
        close $c;
    }
    exit 0;
}
close $srv;

is mx_request( $path, 5, 'ping' ), "echo: ping\n", 'round trip';
is length( mx_request( $path, 5, 'bigreply' ) ), 5001, 'replies longer than 1024 bytes';
is mx_request( $path, 2, 'silent' ), undef, 'empty answer is a failure';
is mx_request( "$dir/nope", 1, 'ping' ), undef, 'unreachable multiplexor';

kill 'TERM', $pid;
waitpid $pid, 0;

done_testing;
