use v5.36;
use strict;
use warnings;

use Test::More;

for my $m (qw(Linux::Epoll Linux::Event::Clock Linux::Event::Timer)) {
    eval "require $m; 1" or plan skip_all => "$m not available: $@";
}

use Linux::Event::Loop;

# Pull masks from the Epoll backend (authoritative for this loop)
use Linux::Event::Reactor::Backend::Epoll ();

my $READABLE = Linux::Event::Reactor::Backend::Epoll::READABLE();
my $WRITABLE = Linux::Event::Reactor::Backend::Epoll::WRITABLE();
my $ERR      = Linux::Event::Reactor::Backend::Epoll::ERR();
my $HUP      = Linux::Event::Reactor::Backend::Epoll::HUP();

sub make_loop () { Linux::Event::Loop->new( model => 'reactor', backend => 'epoll' ) }

subtest "dispatch order: read before write" => sub {
    my $loop = make_loop();

    pipe(my $r, my $w) or die "pipe failed: $!";

    my @order;

    my $wat = $loop->watch($r,
                           read  => sub ($loop, $fh, $w) { push @order, "read" },
                           write => sub ($loop, $fh, $w) { push @order, "write" },
    );

    my $fd = fileno($r);
    ok($wat->{_dispatch_cb}, "watcher has internal dispatch closure");

    $wat->{_dispatch_cb}->($loop, $r, $fd, $READABLE | $WRITABLE, undef);

    is_deeply(\@order, [qw(read write)], "read ran before write");
    $wat->cancel;
};

subtest "mutation rule: if read removes watcher, write does not run" => sub {
    my $loop = make_loop();

    pipe(my $r, my $w) or die "pipe failed: $!";

    my @order;

    my $wat = $loop->watch($r,
                           read  => sub ($loop, $fh, $w) { push @order, "read"; $w->cancel },
                           write => sub ($loop, $fh, $w) { push @order, "write" },
    );

    my $fd = fileno($r);
    $wat->{_dispatch_cb}->($loop, $r, $fd, $READABLE | $WRITABLE, undef);

    is_deeply(\@order, [qw(read)], "write skipped after read removed watcher");
};

subtest "ERR: if error handler exists, it suppresses read/write" => sub {
    my $loop = make_loop();

    pipe(my $r, my $w) or die "pipe failed: $!";

    my @order;

    my $wat = $loop->watch($r,
                           read  => sub ($loop, $fh, $w) { push @order, "read" },
                           write => sub ($loop, $fh, $w) { push @order, "write" },
                           error => sub ($loop, $fh, $w) { push @order, "error" },
    );

    my $fd = fileno($r);
    $wat->{_dispatch_cb}->($loop, $r, $fd, $ERR | $READABLE | $WRITABLE, undef);

    is_deeply(\@order, [qw(error)], "error ran alone; read/write suppressed");
    $wat->cancel;
};

subtest "ERR: without error handler, it behaves like read+write" => sub {
    my $loop = make_loop();

    pipe(my $r, my $w) or die "pipe failed: $!";

    my @order;

    my $wat = $loop->watch($r,
                           read  => sub ($loop, $fh, $w) { push @order, "read" },
                           write => sub ($loop, $fh, $w) { push @order, "write" },
    );

    my $fd = fileno($r);
    $wat->{_dispatch_cb}->($loop, $r, $fd, $ERR, undef);

    is_deeply(\@order, [qw(read write)], "ERR without error cb triggers read+write");
    $wat->cancel;
};

subtest "HUP triggers read (EOF discovery)" => sub {
    my $loop = make_loop();

    pipe(my $r, my $w) or die "pipe failed: $!";

    my @order;

    my $wat = $loop->watch($r,
                           read => sub ($loop, $fh, $w) { push @order, "read" },
    );

    my $fd = fileno($r);
    $wat->{_dispatch_cb}->($loop, $r, $fd, $HUP, undef);

    is_deeply(\@order, [qw(read)], "HUP triggers read");
    $wat->cancel;
};

done_testing;
