#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/lib";
use LP_EnsureArch;

my $arch = LP_EnsureArch::ensure_support('eventfd');

use Errno;
use Fcntl;
use IO::File;

use Test::More;
use Test::FailWarnings;
use Test::SharedFork;

plan 'skip_all' if !$arch;

use Linux::Perl::eventfd;

for my $generic_yn ( 0, 1 ) {
    if ( my $pid = fork ) {
        waitpid $pid, 0;
        die if $?;
    }
    else {
        eval {
            my $class = 'Linux::Perl::eventfd';
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

    note "Using class: $class (PID $$)";

    my $efd = $class->new( initval => 5 );

    my $fileno = $efd->fileno();
    ok( $fileno, 'fileno()' );

    $efd->add(4);
    $efd->add(2);

    is( $efd->read(), 11, 'initval, add, read' );

    open my $dup, '+<&=' . $fileno;

    $dup->blocking(0);

    my $got = $efd->read();
    my $err = $!;
    is( $got, undef, '... after which there is nothing there' );
    is( 0 + $err, Errno::EAGAIN(), '... and $! is EAGAIN' );

    SKIP: {
        skip 'No 64-bit support!', 1 if !eval { pack 'Q', 1 };

        $efd->add( 1 + (2**33) );
        $efd->add(3);

        is( $efd->read(), 4 + (2**33), 'add() and read() 64-bit' )
    }

    my $no_cloexec = `$^X -e'print readlink "/proc/self/fd/$fileno"'`;
    ok( !$no_cloexec, 'verify CLOEXEC by default' );

    #----------------------------------------------------------------------

    my $nb_efd = $class->new( flags => [ 'NONBLOCK' ] );

    open $dup, '+<&=' . $efd->fileno();
    my $flags = fcntl( $dup, Fcntl::F_GETFL(), 0 );

    is(
        $flags & Fcntl::O_NONBLOCK(),
        Fcntl::O_NONBLOCK(),
        'NONBLOCK flag',
    );

    #----------------------------------------------------------------------

    {
        local $^F = 1000;

        my $efd = $class->new();

        my $fileno = $efd->fileno();

        $no_cloexec = `$^X -e'print readlink "/proc/self/fd/$fileno"'`;
        ok( $no_cloexec, 'verify non-CLOEXEC' );

        $efd = $class->new( flags => ['CLOEXEC'] );
        $fileno = $efd->fileno();

        $no_cloexec = `$^X -e'print readlink "/proc/self/fd/$fileno"'`;
        ok( !$no_cloexec, 'verify CLOEXEC flag' );
    }

    return;
}

done_testing() if $arch;
