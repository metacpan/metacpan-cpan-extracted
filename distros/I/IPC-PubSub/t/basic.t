use strict;
use warnings;
use Test::More;
use IPC::PubSub;
use IO::Socket::INET;
use File::Temp ':POSIX';


my @backends = qw(PlainHash);

unshift @backends, 'DBM_Deep' if eval { require DBM::Deep };
unshift @backends, 'JiftyDBI' if eval { require Jifty::DBI };
unshift @backends, 'Memcached' if eval { require Cache::Memcached } and IO::Socket::INET->new('127.0.0.1:11211');

plan tests => 15 * scalar @backends;

my $tmp = tmpnam();
END { unlink $tmp }

my %init_args = (
    DBM_Deep    => [ $tmp ],
    JiftyDBI    => [ db_init => 1 ],
    Memcached   => [ rand() . $$ ],
);

SKIP: for my $backend (@backends) {
    diag("Testing backend $backend");

    my $bus = IPC::PubSub->new($backend, @{$init_args{$backend}});

    my @sub; $sub[0] = $bus->new_subscriber;

    is_deeply([map {$_->[1]} @{$sub[0]->get_all->{''}}], [], 'get_all worked when there is no pubs');
    is_deeply([$sub[0]->get], [], 'get_all worked when there is no pubs');

    my $pub = $bus->new_publisher;

    $pub->msg('foo');

    $sub[1] = $bus->new_subscriber;

    $pub->msg(['bar', 'bar']);
    $pub->msg('baz');

    my $got = $sub[0]->get;
    is($got->[0], 'foo', 'get worked');
    is($got->[1][0], 'bar', 'get worked');
    is($got->[1][1], 'bar', 'get worked');
    is($got->[2], 'baz', 'get worked');
    is_deeply([$sub[0]->get], [], 'get emptied the cache');

    is_deeply([map {ref($_) ? [@$_] : $_} map {$_->[1]} @{$sub[1]->get_all->{''}}], [['bar', 'bar'], 'baz'], 'get_all worked');
    is_deeply([map {ref($_) ? [@$_] : $_} map {$_->[1]} @{$sub[1]->get_all->{''}}], [], 'get_all emptied the cache');

    is($bus->modify('key'), undef, 'modify (1)');
    is($bus->modify('key' => 'val'), 'val', 'modify (2)');
    is($bus->modify('key'), 'val', 'modify (3)');
    is($bus->modify('key' => sub { s/v/h/ }), 1, 'modify (4)');
    is($bus->modify('key'), 'hal', 'modify (5)');
    is($bus->modify('key' => undef), undef, 'modify (6)');
}
