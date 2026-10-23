use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);
use EV;
use EV::Kafka;

sub retain { my $token = shift; return sub { $token } }
my ($weak_token, $weak_loop);
{
    my $loop = EV::Loop->new;
    $weak_loop = $loop;
    weaken $weak_loop;
    my $token = bless {}, 'Local::Token';
    $weak_token = $token;
    weaken $weak_token;
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', $loop);
    $conn->on_error(retain($token));
    undef $token;
    undef $conn;
    undef $loop;
    ok !defined($weak_token), 'handler is released before the calling scope ends';
    ok !defined($weak_loop), 'loop is released before the calling scope ends';
}
ok !defined($weak_token), 'connection releases native handler storage without a loop iteration';
ok !defined($weak_loop), 'connection releases its custom loop without running it';
done_testing;
