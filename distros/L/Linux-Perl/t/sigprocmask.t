#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::Deep;
use Test::FailWarnings -allow_deps => 1;
use Test::SharedFork;

use FindBin;
use lib "$FindBin::Bin/lib";

use LP_EnsureArch;

LP_EnsureArch::ensure_support('sigprocmask');

use Linux::Perl::sigprocmask;

#----------------------------------------------------------------------

for my $generic_yn ( 0, 1 ) {
    if ( my $pid = fork ) {
        waitpid $pid, 0;
        die "exit failure: $?" if $?;
    }
    else {
        eval {
            my $class = 'Linux::Perl::sigprocmask';
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

    diag 'blocking USR1 via block()';

    my @old_sigs = $class->block('USR1');

    _confirm_non_receipt('USR1');

    diag 'unblocking USR1';

    pipe(my $r, my $w);
    vec( my $rin = q<>, fileno($r), 1 ) = 1;

    local $SIG{'USR1'} = sub { syswrite($w, 'x') };

    $class->unblock('USR1');

    diag 'waiting for USR1 self-pipe';

    is(
        0 + select( my $rout = $rin, undef, undef, 30 ),
        1,
        'signal delivered after unblocked',
    );

    #----------------------------------------------------------------------

    diag 'blocking USR2 via set()';

    $class->set('USR2');

    _confirm_non_receipt('USR2');

    pipe($r, $w);
    vec( $rin = q<>, fileno($r), 1 ) = 1;

    local $SIG{'USR2'} = sub { syswrite($w, 'x') };

    $class->set();

    is(
        0 + select( $rout = $rin, undef, undef, 30 ),
        1,
        'USR2 delivered after unblocked (via set())',
    );

    $class->set(@old_sigs);

    cmp_bag(
        [ $class->block() ],
        \@old_sigs,
        'empty block() returns the (restored) current set',
    );

    return;
}

sub _confirm_non_receipt {
    my ($sig) = @_;

    pipe(my $r, my $w);

    local $SIG{$sig} = sub { syswrite($w, 'x') };

    diag "self-sending $sig";

    kill $sig, $$;

    diag "waiting for $sig self-pipe";

    vec( my $rin = q<>, fileno($r), 1 ) = 1;
    is(
        0 + select( my $rout = $rin, undef, undef, 1 ),
        0,
        "signal $sig not delivered while blocked",
    );

    return;
}

done_testing();
