#!perl -w
BEGIN { require 't/common.pl' }

use Test::More 'no_plan';
use_ok("Mail::Thread");

{
  package Mail::Thread::Open;
  @Mail::Thread::Open::ISA = qw(Mail::Thread);
  sub _finish { }
}

my @messages = slurp_messages('t/testbox-2');
my $tail = pop @messages;
my $threader = Mail::Thread::Open->new(@messages);

my @stuff;
$threader->thread;
$threader->_add_message($tail);

is($threader->rootset, 1, "We have one main threads");

dump_into($threader => \@stuff);
# Dump(\@stuff);

deeply(\@stuff, [
    [ 0, "sort numbers", '20030101210258.63148.qmail@web20805.mail.yahoo.com' ],
    [ 1, "Re: sort numbers", 'auvpjq$ede$1@post.home.lunix' ],
    [ 1, "Re: sort numbers", 'r3i71vcul4g95orb58173qj6b8dus6pnch@4ax.com' ]
   ]);
