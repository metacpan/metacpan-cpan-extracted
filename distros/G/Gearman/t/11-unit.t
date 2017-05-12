use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::Socket::IP;
use Perl::OSType qw/ is_os_type /;

my $mn = "Gearman::Util";

use_ok($mn);

no strict "refs";

my @chr = ('a' .. 'z', 'A' .. 'Z', 0 .. 9);

ok(my %cmd = %{"$mn\:\:cmd"});
is(keys(%cmd), 31);

foreach my $n (keys %cmd) {
    my $t = $cmd{$n}->[1];
    my $a = join '', map { @chr[rand @chr] } 0 .. int(rand(20)) + 1;

    is(&{"$mn\:\:cmd_name"}($n), $t, "$mn\:\:cmd($n) = $t");

    is(
        &{"$mn\:\:pack_req_command"}($t),
        join('', "\0REQ", pack("NN", $n, 0), ''),
        "$mn\:\:pack_req_command}($t)"
    );

    is(
        &{"$mn\:\:pack_res_command"}($t),
        join('', "\0RES", pack("NN", $n, 0), ''),
        "$mn\:\:pack_res_command}($t)"
    );

    is(
        &{"$mn\:\:pack_req_command"}($t, $a),
        join('', "\0REQ", pack("NN", $n, length($a)), $a),
        "$mn\:\:pack_req_command}($t, $a)"
    );

    is(
        &{"$mn\:\:pack_res_command"}($t, $a),
        join('', "\0RES", pack("NN", $n, length($a)), $a),
        "$mn\:\:pack_res_command}($t)"
    );
} ## end foreach my $n (keys %cmd)

throws_ok(sub { &{"$mn\:\:pack_req_command"}() },    qr/Bogus type arg of/);
throws_ok(sub { &{"$mn\:\:pack_req_command"}('x') }, qr/Bogus type arg of/);
throws_ok(sub { &{"$mn\:\:pack_res_command"}() },    qr/Bogus type arg of/);
throws_ok(sub { &{"$mn\:\:pack_res_command"}('x') }, qr/Bogus type arg of/);

#TODO read_res_packet
# use Socket qw/
#     IPPROTO_TCP
#     TCP_NODELAY
#     SOL_SOCKET
#     PF_INET
#     SOCK_STREAM
#     /;
# subtest "read_res_packet", sub {
#     my $s = IO::Socket::INET->new(
#         # PeerAddr => "localhost:4730",
#         # Timeout  => 1
#     );

#     # $s->autoflush(1);
#     # setsockopt($s, IPPROTO_TCP, TCP_NODELAY, pack("l", 1)) or die;

#     is(&{"$mn\:\:read_res_packet"}($s, \my $e), undef);
#     is($e, "eof");
# };

subtest "read_text_status", sub {
    is(&{"$mn\:\:read_text_status"}(IO::Socket::IP->new(), \my $e), undef);
    is($e, "can't read from unconnected socket");
};

subtest "send_req", sub {
    is(&{"$mn\:\:send_req"}(IO::Socket::IP->new(), \"foo"), 0);
};

subtest "wait_for_readability", sub {
    is_os_type("Windows") && plan skip_all => "Windows test in TODO";
    is(&{"$mn\:\:wait_for_readability"}(2, 3), 0);
};

done_testing();

