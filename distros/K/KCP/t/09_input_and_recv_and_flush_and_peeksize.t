#
# Copyright (c) homqyy
#
use strict;
use warnings;

use KCP;
use Test::More tests => 9;

#########################

sub output
{
    my ($data, $user) = @_;

    ok($user->{peer_kcp}->input($data), "input")
}

my $g_time = 10;
sub get_current_time
{
    my $kcp = shift;

    my $ret = $g_time;

    $g_time += $kcp->get_interval;
}

my (%user1, %user2);

my $kcp1 = KCP::new(1, \%user1)->set_output(\&output);
my $kcp2 = KCP::new(1, \%user2)->set_output(\&output);

$user1{kcp} = $kcp1;
$user1{peer_kcp} = $kcp2;

$user2{kcp} = $kcp2;
$user2{peer_kcp} = $kcp1;

# update
$kcp1->update(&get_current_time($kcp1));
$kcp2->update(&get_current_time($kcp2));

# kcp1 send data and kcp2 recv data
{
    # kcp1 send data
    my $send_data = "123" x 10;
    $kcp1->send($send_data);
    $kcp1->update(&get_current_time($kcp1));

    # kcp2 recv data
    $kcp2->update(&get_current_time($kcp2));

    my $recv_data;
    ok($kcp2->recv($recv_data, length $send_data), "recv data");
    is($recv_data, $send_data, "check received data");

    is($kcp2->recv($recv_data, length $send_data), undef, "no data to receive");
}

# kcp1 again send data and flush immediately.
# kcp2 peek data size and recv it
{
    my $send_data = "123" x 10;

    $kcp1->send($send_data);
    isa_ok($kcp1->flush, 'KCP', "flush");

    my $size = $kcp2->peeksize;
    is($size, length $send_data, "peeksize");

    my $recv_data;
    $kcp2->recv($recv_data, $size);
    is($recv_data, $send_data, "check data after flush");
}