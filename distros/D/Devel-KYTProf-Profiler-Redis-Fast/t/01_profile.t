use strict;
use Test::More 0.98;
use Redis::Fast;
use Devel::KYTProf ();
use Test::TCP;

Devel::KYTProf->apply_prof('Redis::Fast');
Devel::KYTProf->logger('Mock');

my $bin = 'redis-server';
if ( qx{$bin --version} !~ /^Redis/ ) {
    plan skip_all => 'redis-server missing. skip testing';
}

subtest 'post' => sub {
    test_tcp(
        client => sub {
            my $port = shift;

            my $redis = Redis::Fast->new( server => "127.0.0.1:$port" );
            ok $redis;

            my $prof;
            $redis->set('foo' => 'bar');
            ok $prof = Mock->pop;
            is_deeply $prof->{data} => {
                command => 'SET',
                key     => 'foo',
            };

            $redis->mget('foo', 'bar');
            ok $prof = Mock->pop;
            is_deeply $prof->{data} => {
                command => 'MGET',
                key     => 'foo bar',
            };

            $redis->mget('x' x 128, 'y' x 128, 'z' x 128);
            ok $prof = Mock->pop;
            is_deeply $prof->{data} => {
                command => 'MGET',
                key     => 'x' x 128 . " ". 'y' x 123 . "...",
            };

            $redis->info;
            ok $prof = Mock->pop;
            is_deeply $prof->{data} => {
                command => 'INFO',
            };

            $redis->keys("*");
            ok $prof = Mock->pop;
            is_deeply $prof->{data} => {
                command => 'KEYS',
                args    => '*',
            };

            $redis->subscribe("ch1", "ch2", sub { warn "@_" });
            ok $prof = Mock->pop;
            is_deeply $prof->{data} => {
                command => 'SUBSCRIBE',
                args    => 'ch1 ch2',
            };
        },
        server => sub {
            my $port = shift;
            exec $bin, '--port', $port, '--save', '';
            die "cannot execute $bin $!";
        },
    );
};

done_testing;

package Mock;
my @logs;
sub log {
    my ($class, %args) = @_;
#    Test::More::diag Test::More::explain \%args;
    push @logs, \%args;
}

sub pop {
    pop @logs;
}

