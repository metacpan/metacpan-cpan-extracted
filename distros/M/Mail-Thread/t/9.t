#!perl -w
BEGIN { require 't/common.pl' }

use Test::More tests => 3;
use_ok("Mail::Thread");

# this tests subject threading
my $threader = new Mail::Thread(slurp_messages('t/testbox-9'));
$threader->thread;

is($threader->rootset, 1, "We have one thread");

my @stuff;
dump_into( $threader => \@stuff );

deeply(\@stuff,
       [
         [ 0, "Perl 6 Apocalypse 6",     '20030311083936.GB26176@cat.ourshack.com' ],
         [ 1, "Re: Perl 6 Apocalypse 6", 'f05200f00ba93600e2e7a@10.0.0.250' ],
         [ 2, "Re: Perl 6 Apocalypse 6", '1047382472.1875.19.camel@dirk2.int.tobit.co.uk' ],
         [ 3, "Re: Perl 6 Apocalypse 6", 'D4CA215C-53B6-11D7-8510-0030654E40D0@quietstars.com' ],
         [ 1, "Re: Perl 6 Apocalypse 6", '11030370.22639@webbox.com' ],
         [ 2, "Re: Perl 6 Apocalypse 6", '86fzpu3r6o.fsf@red.stonehenge.com' ],
       ], "It all works");


