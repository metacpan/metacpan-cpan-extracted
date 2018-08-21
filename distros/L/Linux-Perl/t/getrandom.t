#!/usr/bin/env perl

use Test::More;
use Test::FailWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use LP_EnsureArch;

LP_EnsureArch::ensure_support('getrandom');

use Errno ();

use Linux::Perl::getrandom ();

my $buf = "\0" x 24;

SKIP: {
    my $numbytes = eval {
        my $numbytes = Linux::Perl::getrandom->getrandom(
            buffer => \$buf,
        );
    };
    my $err = $@;

    if ($err && $err->get('error') == Errno::ENOSYS()) {
        skip "This system lacks support for “getrandom”.", 2;
    }

    is( $numbytes, length($buf), 'number of bytes returned' );

    isnt(
        $buf,
        ("\0" x 24),
        'buffer has changed',
    );
}

done_testing();
