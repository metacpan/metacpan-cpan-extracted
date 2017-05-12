#!perl -w
BEGIN { require 't/common.pl' }

use Test::More tests => 3;
use_ok("Mail::Thread");

my $threader = new Mail::Thread( slurp_messages('t/testbox') );
{
	no warnings 'once';
	$Mail::Thread::debug=0;
	$Mail::Thread::noprune=1;
	$Mail::Thread::nosubject=1;
	$threader->thread;
}

is($threader->rootset, 3, "We have three main threads");

my @stuff;
dump_into($threader => \@stuff);

deeply(\@stuff, [
    [ 0, "[ Message not available ]",                       '3E1A9807.3393A163@earthlink.net' ],
    [ 1, "[p5ml] Re: karie kahimi binge...help needed",     'avefva+gol5@eGroups.com' ],
    [ 2, "RE: [p5ml] Re: karie kahimi binge...help needed", '000001c2b64c$03af8740$56734151@noos.fr' ],
    [ 1, "Re: [p5ml] karie kahimi binge...help needed",     '4.3.2-J.20030107222402.051f7418@mail.chipple.net' ],
    [ 2, "Re: [p5ml] karie kahimi binge...help needed",     '3E1B380C.F5713721@earthlink.net' ],
    [ 1, "R: [p5ml] karie kahimi binge...help needed",      '000f01c2b6ab$2017f8e0$25197450@win98' ],
    [ 0, "[rt-users] Configuration Problem",                '20030107164205.E98585-100000@nemesis.eahd.or.ug' ],
    [ 1, "Re: [rt-users] Configuration Problem",            '20030107145325.33120.qmail@web13704.mail.yahoo.com' ],
    [ 0, '[ Message not available ]',                       '20021112174425.GD13228@soto.kasei.com' ],
    [ 1, '[ Message not available ]',                       '20021112174700.GB2599@rivendale.net' ],
    [ 2, "Re: January's meeting",                           '20030107153054.GB21728@soto.kasei.com' ],
    [ 3, "Re: January's meeting",                           '20030107160909.GA11673@futureless.org' ],
    [ 4, "Re: January's meeting",                           '20030107161602.GA8784@labac.net' ],
   ], "It all works");

