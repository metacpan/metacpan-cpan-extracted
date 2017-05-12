#!perl -w
BEGIN { require 't/common.pl' }

use Test::More tests => 3;
use_ok("Mail::Thread");
my $threader = new Mail::Thread(slurp_messages('t/testbox-4'));
no warnings 'once';
$Mail::Thread::nosubject=1;
$threader->thread;

is($threader->rootset, 2, "We have two main threads");
my @stuff;
dump_into($threader => \@stuff);

deeply(\@stuff, [
    [ 0, 'Working Group Proposal', '20000719155037.A27886@O2.chapin.edu' ],
    [ 1, 'Re: Working Group Proposal', '20000719161418.D17718@ghostwheel.wks.na.deuba.com' ],
    [ 2, 'Re: Working Group Proposal', '20000719154851.C5309@cbi.tamucc.edu' ],
    [ 3, 'Re: Working Group Proposal', '20000719164529.E17718@ghostwheel.wks.na.deuba.com' ],
    [ 4, 'Re: Working Group Proposal', '20000719160141.D5309@cbi.tamucc.edu' ],
    [ 1, 'Re: Working Group Proposal', '87em4pa0ec.fsf@fire-swamp.org' ],
    [ 0, 'Re: Working Group Proposal', 'F122YsoaJ70EgyBiQhe00003799@hotmail.com' ],
   ]
 );
