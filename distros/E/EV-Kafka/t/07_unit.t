use strict;
use warnings;
use Test::More;
use EV::Kafka;

plan tests => 18;

# --- new() option parsing ---
{
    my $k = EV::Kafka->new(
        brokers => '10.0.0.1:9092, 10.0.0.2 , 10.0.0.3:9094',
        acks    => 0,
        on_error => sub {},
    );
    isa_ok $k, 'EV::Kafka::Client';
    my $bs = $k->{cfg}{bootstrap};
    is scalar @$bs, 3, 'parsed 3 bootstrap brokers';
    is $bs->[0][0], '10.0.0.1', 'host 1';
    is $bs->[0][1], 9092, 'port 1';
    is $bs->[1][0], '10.0.0.2', 'host 2 trimmed';
    is $bs->[1][1], 9092, 'port 2 default';
    is $bs->[2][1], 9094, 'port 3 explicit';
    is $k->{cfg}{acks}, 0, 'acks=0';
}

# --- default options ---
{
    my $k = EV::Kafka->new(on_error => sub {});
    is $k->{cfg}{acks}, -1, 'default acks=-1';
    is $k->{cfg}{client_id}, 'ev-kafka', 'default client_id';
    ok !$k->{cfg}{tls}, 'default tls off';
}

# --- _assign_partitions ---
{
    my $k = EV::Kafka->new(on_error => sub {});
    # seed synthetic metadata
    $k->{cfg}{meta} = {
        topics => [
            {
                name => 'topic-a',
                partitions => [
                    { partition => 0, leader => 1 },
                    { partition => 1, leader => 2 },
                    { partition => 2, leader => 1 },
                    { partition => 3, leader => 2 },
                ],
            },
        ],
    };

    # 2 members, 4 partitions -> roundrobin: member0 gets p0,p2; member1 gets p1,p3
    my $members = [
        { member_id => 'member-a' },
        { member_id => 'member-b' },
    ];
    my $assignments = $k->_assign_partitions($members, ['topic-a']);
    is scalar @$assignments, 2, '2 assignments for 2 members';

    # decode assignment for member-a (first, gets even indices)
    my $a0 = $assignments->[0];
    is $a0->{member_id}, 'member-a', 'first assignment is member-a';
    ok length($a0->{assignment}) > 6, 'assignment bytes non-empty';

    # decode assignment for member-b
    my $a1 = $assignments->[1];
    is $a1->{member_id}, 'member-b', 'second assignment is member-b';

    # 1 member, 4 partitions -> gets all 4
    my $solo = $k->_assign_partitions(
        [{ member_id => 'solo' }], ['topic-a']
    );
    is scalar @$solo, 1, '1 assignment for solo member';

    # 3 members, 4 partitions -> 2,1,1 distribution
    my $three = $k->_assign_partitions(
        [{ member_id => 'a' }, { member_id => 'b' }, { member_id => 'c' }],
        ['topic-a']
    );
    is scalar @$three, 3, '3 assignments for 3 members';
}

# --- EV::Kafka::Conn basic ---
{
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    ok !$conn->connected, 'conn not connected initially';
}
