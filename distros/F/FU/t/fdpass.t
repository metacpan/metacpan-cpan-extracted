use v5.36;
use Test::More;
use IO::Socket qw/AF_UNIX SOCK_STREAM PF_UNSPEC/;

BEGIN { use_ok 'FU::Util', qw/fdpass_send fdpass_recv/ }

my ($rd, $wr) = IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC);

is $wr->syswrite("abc", 3), 3;

my ($fd, $buf) = fdpass_recv fileno($rd), 10;
ok !defined $fd;
is $buf, 'abc';

is fdpass_send(fileno($wr), fileno($wr), 'def'), 3;

($fd, $buf) = fdpass_recv fileno($rd), 50;
ok $fd > 0;
is $buf, 'def';

# Check that $fd is indeed an alias for $wr
my $nwr = IO::Socket->new_from_fd($fd, 'w');
is $nwr->syswrite('hij'), 3;
is $rd->sysread($buf, 20), 3;
is $buf, 'hij';

$nwr->close;
$wr->close;

($fd, $buf) = fdpass_recv fileno($rd), 10;
ok !defined $fd;
is $buf, '';

($fd, $buf) = fdpass_recv -1, 10;
ok !defined $fd;
ok !defined $buf;
is fdpass_send(-1, 3, 'x'), -1;

done_testing;
