use v5.36;
use strict;
use warnings;

use Test::More;

for my $m (qw(Linux::Event::Clock Linux::Event::Timer)) {
    eval "require $m; 1" or plan skip_all => "$m not available: $@";
}

use Linux::Event::Loop;

# Pull masks from the Epoll backend (authoritative for this loop)
use Linux::Event::Backend::Epoll ();
use Linux::Event::XS ();

my $READABLE = Linux::Event::Backend::Epoll::READABLE();
my $WRITABLE = Linux::Event::Backend::Epoll::WRITABLE();
my $ERR      = Linux::Event::Backend::Epoll::ERR();
my $HUP      = Linux::Event::Backend::Epoll::HUP();

sub dispatch_watcher ($loop, $fh, $mask) {
    my $fd = fileno($fh);
    my $rec = Linux::Event::XS::registry_get($loop->backend->{watch}, $fd);
    ok($rec, "watcher has backend dispatch record");
    Linux::Event::XS::backend_watch_dispatch_mask($rec, $mask);
}

sub make_loop () { Linux::Event::Loop->new(backend => 'epoll') }

subtest "dispatch order: read before write" => sub {
    my $loop = make_loop();

    pipe(my $r, my $w) or die "pipe failed: $!";

    my @order;

    my $wat = $loop->watch($r,
                           read  => sub ($loop, $fh, $w) { push @order, "read" },
                           write => sub ($loop, $fh, $w) { push @order, "write" },
    );

    dispatch_watcher($loop, $r, $READABLE | $WRITABLE);

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

    dispatch_watcher($loop, $r, $READABLE | $WRITABLE);

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

    dispatch_watcher($loop, $r, $ERR | $READABLE | $WRITABLE);

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

    dispatch_watcher($loop, $r, $ERR);

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

    dispatch_watcher($loop, $r, $HUP);

    is_deeply(\@order, [qw(read)], "HUP triggers read");
    $wat->cancel;
};

done_testing;
