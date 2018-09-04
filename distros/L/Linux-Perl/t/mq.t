#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings -allow_deps => 1;
use Test::SharedFork;

use FindBin;
use lib "$FindBin::Bin/lib";

use LP_EnsureArch;

LP_EnsureArch::ensure_support('mq');

use Linux::Perl::mq;

#----------------------------------------------------------------------

for my $generic_yn ( 0, 1 ) {
    if ( my $pid = fork ) {
        waitpid $pid, 0;
        die if $?;
    }
    else {
        eval {
            my $class = 'Linux::Perl::mq';
            if (!$generic_yn) {
                require Linux::Perl::ArchLoader;
                $class = Linux::Perl::ArchLoader::get_arch_module($class);
            };

            _do_tests($class);
        };
        die if $@;
        exit;
    }
}

sub _do_tests {
    my ($class) = @_;

    diag "======= CLASS: $class";

    my $mq = $class->new(
        name => 'my_test_queue',
        #flags => ['CREAT', 'EXCL'],
        flags => ['CREAT'],
        mode => 0700,
        msgsize => 16,
        maxmsg => 4,
    );

    my $attr = $mq->getattr();

    is_deeply(
        $attr,
        {
            flags => 0,
            maxmsg => 4,
            msgsize => 16,
            curmsgs => 0,
        },
        'getattr() return',
    );

    #my $fileno = fileno $mq;
    my $fileno = $mq->[0];

    like(
        CORE::readlink("/proc/$$/fd/$fileno"),
        qr<my_test_queue>,
        'fileno',
    );

    is(
        $mq->blocking(),
        1,
        'blocking() return (truthy)',
    );

    $mq->blocking(1);

    my $received_msg = "\0" x 20;

    is(
        $mq->receive( \$received_msg ),
        undef,
        'receive() gives undef when not ready (blocking)',
    );

    $mq->blocking(0);

    is(
        $mq->blocking(),
        !1,
        'blocking() return (falsy)',
    );

    is(
        $mq->receive( \$received_msg ),
        undef,
        'receive() gives undef when not ready (non-blocking)',
    );

    ok(
        $mq->send( msg => 'Hello.' ),
        'send() truthy when it works',
    );

    my $msg_len = $mq->receive( \$received_msg );

    is( substr($received_msg, 0, $msg_len), 'Hello.', 'receive()' );

    undef $mq;

    ok(
        !defined( CORE::readlink("/proc/$$/fd/$fileno") ),
        'cleanup message queue',
    );

    my $did_unlink = $class->unlink('my_test_queue');
    ok( $did_unlink, 'unlinked test queue' );

    return;
}

done_testing();
