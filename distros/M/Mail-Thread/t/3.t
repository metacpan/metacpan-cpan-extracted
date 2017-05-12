#!perl -w
BEGIN { require 't/common.pl' }

use Test::More tests => 3;
use_ok("Mail::Thread");

my $threader = new Mail::Thread(slurp_messages('t/testbox-3'));
$threader->thread;

is($threader->rootset, 1, "We have one main thread");
my @stuff;
dump_into($threader => \@stuff );

deeply(\@stuff, [
    [ 0, '[ Message not available ]', '20030102152943.D635@hermione.osp.nl' ],
    [ 1, 'Re: Zip/Postal codes.', '3E146C15.8000302@ntlworld.com' ],
    [ 2, 'Re: Zip/Postal codes.', '20030102180231.F635@hermione.osp.nl' ],
    [ 1, 'Re: Zip/Postal codes.', '20030102115117.A21351@cs839290-a.mtth.phub.net.cable.rogers.com' ],
   ]
 );
