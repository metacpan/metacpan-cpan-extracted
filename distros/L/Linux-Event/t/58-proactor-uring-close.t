use v5.36;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM);

use Linux::Event::Proactor;

eval { require IO::Uring; 1 } or plan skip_all => 'IO::Uring not available';

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, 0)
    or die "socketpair failed: $!";

my $loop = Linux::Event::Proactor->new(backend => 'uring');

my $called = 0;
my $op = $loop->close(
    fh => $a,
    on_complete => sub ($op, $result, $ctx) {
        $called++;
        is($op->state, 'done', 'uring close done');
        is_deeply($result, {}, 'uring close result');
    },
);

for (1 .. 50) {
    $loop->run_once;
    last if $called;
}

is($called, 1, 'uring close callback fired');

my $buf = '';
my $n = sysread($b, $buf, 1);
ok(defined($n), 'peer read defined after close');
is($n, 0, 'peer sees EOF after close');

done_testing;
