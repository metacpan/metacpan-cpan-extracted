#!/usr/bin/env perl
# test the lexicon index.

use warnings;
use strict;

use Test::More;

my $mailman_po;
my $not_exist = 'does-not-exist';

BEGIN
{   $mailman_po = '/usr/lib/mailman/messages';
    unless(-d $mailman_po)
    {   plan skip_all => 'cannot find sample translations, no problem';
        exit 0;
    }
    plan tests => 12;
}

use Log::Report;
use_ok('Log::Report::Lexicon::Index');

#
# Directory does not exist
#

my $t = Log::Report::Lexicon::Index->new($not_exist);
ok(defined $t, 'create useless index');
isa_ok($t, 'Log::Report::Lexicon::Index');
ok(!defined $t->find('domain', 'locale'));

#
# Now it does exist
#

my $v = Log::Report::Lexicon::Index->new($mailman_po);
ok(defined $v, 'create mailman index');
isa_ok($v, 'Log::Report::Lexicon::Index');
ok(defined $v->index);
is($v->find('mailman', 'nl_NL.utf-8@test'), $mailman_po.'/nl/LC_MESSAGES/mailman.mo');
is($v->find('mailman', 'pt_BR'), $mailman_po.'/pt_BR/LC_MESSAGES/mailman.mo');
ok(!defined $v->find('mailman', 'xx_XX.ISO-8859-1@modif'));

#use Data::Dumper;
#warn Dumper $v;

#
# list textdomain files
#

my @l = $v->list('mailman');
ok(@l+0, 'list');
cmp_ok(scalar(@l), '>', 30);   # I have 58, on the moment
