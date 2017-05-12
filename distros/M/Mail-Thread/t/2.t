#!perl -w
BEGIN { require 't/common.pl' }

use Test::More tests => 9;
use_ok("Mail::Thread");

my $threader = new Mail::Thread(slurp_messages('t/testbox-2'));

my @stuff;
for (0..3) { # This tests that multiple applications of the algorithm work OK.
    @stuff = ();
    $threader->thread;

    is($threader->rootset, 1, "We have one main threads");

    my @stuff;
    dump_into($threader => \@stuff);

    deeply(\@stuff, [
        [ 0, "sort numbers", '20030101210258.63148.qmail@web20805.mail.yahoo.com' ],
        [ 1, "Re: sort numbers", 'auvpjq$ede$1@post.home.lunix' ],
        [ 1, "Re: sort numbers", 'r3i71vcul4g95orb58173qj6b8dus6pnch@4ax.com' ]
       ]);
}

