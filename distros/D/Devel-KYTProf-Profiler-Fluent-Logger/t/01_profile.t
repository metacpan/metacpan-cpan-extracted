use strict;
use Test::More 0.98;
use Fluent::Logger;
use Devel::KYTProf ();
use Test::TCP;

#Devel::KYTProf->ignore_class_regex('Class::
Devel::KYTProf->apply_prof('Fluent::Logger');
Devel::KYTProf->logger('Mock');

subtest 'post' => sub {
    test_tcp(
        client => sub {
            my $port = shift;

            my $logger = Fluent::Logger->new({
                port => $port,
            });
            ok $logger;

            ok my $prof = Mock->pop;
            is_deeply $prof->{data} => {
                method => '_connect',
                host   => '127.0.0.1',
                port   => $port,
            };

            my $now = time;
            ok $logger->post_with_time("test.message" => { foo => "bar" }, $now);
            ok $prof = Mock->pop;
            my $size = delete $prof->{data}->{message_size};
            ok $size >= 7;
            is_deeply $prof->{data} => {
                method       => '_post',
                tag          => "test.message",
                message_time => $now,
            };

            $logger->close;
            ok $prof = Mock->pop;
            is_deeply $prof->{data} => {
                method => 'close',
                host   => '127.0.0.1',
                port   => $port,
            };
        },
        server => sub {
            my $port = shift;

            my $sock = IO::Socket::INET->new(
                LocalPort => $port,
                LocalAddr => '127.0.0.1',
                Proto     => 'tcp',
                Listen    => 5,
            ) or die "Cannot open server socket: $!";

            $sock->listen or die $!;
            while (my $c = $sock->accept) {
                print $c;
            }
        },
    );
};

done_testing;

package Mock;
my @logs;
sub log {
    my ($class, %args) = @_;
    push @logs, \%args;
}

sub pop {
    pop @logs;
}

