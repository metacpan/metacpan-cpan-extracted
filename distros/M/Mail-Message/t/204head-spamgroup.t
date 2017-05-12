#!/usr/bin/env perl
#
# Test the processing of spam groups.
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Head::Complete;
use Mail::Message::Head::SpamGroup;

use File::Spec;
use Test::More;
use File::Basename qw(dirname);

BEGIN {
    eval { require Mail::Box::Mbox };
    if($@)
    {   plan skip_all => 'these tests need Mail::Box::Mbox';
        exit 0;
    }
    else
    {   plan tests => 75;
    }
}

#
# Creation of a group
#

my $sg = Mail::Message::Head::SpamGroup->new;

ok(defined $sg,                           'simple construction');
isa_ok($sg, 'Mail::Message::Head::SpamGroup');

#
# Extraction of a group
#

my $h = Mail::Message::Head::Complete->new;
ok(defined $h);

my @sgs = Mail::Message::Head::SpamGroup->from($h);
ok(!@sgs,                                 "no spamgroups in empty header");

#
# Open folder with example messages
#

my $fn = dirname(__FILE__).'/204-sgfolder.mbox';
die "Cannot find file with spam filter examples ($fn)" unless -f $fn;

my $folder = Mail::Box::Mbox->new(folder => $fn, extract => 'ALWAYS');
ok(defined $folder,                   "open example folder");
die unless defined $folder;

my @msgs   = $folder->messages;
cmp_ok(scalar(@msgs), '==', 11,        "all expected messages present");

for(my $nr=0; $nr<5; $nr++)
{  my $msg = $folder->message($nr);
   my @sgs = $msg->head->spamGroups;

   cmp_ok(scalar(@sgs), '==', 1,      "spam group at $nr");
   
   my $sg = $sgs[0];
   is($sg->type, "SpamAssassin");

   $sg->delete;

   @sgs   = $msg->head->spamGroups;
   cmp_ok(scalar(@sgs), '==', 0,      "spam group $nr removed");
}

for(my $nr=5; $nr<10; $nr++)
{   my $msg  = $folder->message($nr);
    my $head = $msg->head;

    my @sgs = $head->spamGroups;
    cmp_ok(scalar(@sgs), '==', 1,      "spam group at $nr");
    my $sg0 = $sgs[0];
    is($sg0->type, "Habeas-SWE");

    my $sg  = $msg->head->spamGroups('Habeas-SWE');
    ok(defined $sg);
    is($sg->type, "Habeas-SWE");

    my $is_correct    = ($nr==5 || $nr==6) ? 1 : 0;
    my $found_correct = $sg->habeasSweFieldsCorrect || 0;
    cmp_ok($found_correct, '==', $is_correct, "spam in $nr");

    $found_correct
      = Mail::Message::Head::SpamGroup->habeasSweFieldsCorrect($msg)  || 0;
    cmp_ok($found_correct, '==', $is_correct, "spam in message $nr");

    $found_correct
      = Mail::Message::Head::SpamGroup->habeasSweFieldsCorrect($head) || 0;
    cmp_ok($found_correct, '==', $is_correct,  "spam in head of message $nr");

    $sg->delete;

    @sgs   = $msg->head->spamGroups;
    cmp_ok(scalar(@sgs), '==', 0,       "spam group $nr removed");
}

my $msg  = $folder->message(10);
my $head = $msg->head;
ok(Mail::Message::Head::SpamGroup->habeasSweFieldsCorrect($msg));
ok(Mail::Message::Head::SpamGroup->habeasSweFieldsCorrect($head));

@sgs     = sort {$a->type cmp $b->type} $head->spamGroups;
cmp_ok(scalar(@sgs), '==', 2,           "message 11 with 2 groups");

is($sgs[0]->type, 'Habeas-SWE');
ok($sgs[0]->habeasSweFieldsCorrect);
is($sgs[1]->type, 'SpamAssassin');

my $sgs  = $head->spamGroups;
cmp_ok($sgs, '==', 2,                   "scalar context = amount");

my $sa   = $head->spamGroups('SpamAssassin');
ok(defined $sa,                         "found spam assassin group");

my $swe  = $head->spamGroups('Habeas-SWE');
ok($swe->habeasSweFieldsCorrect);
ok(defined $swe,                        "found habeas-swe group");

$sa->delete;
@sgs     = $head->spamGroups;
cmp_ok(scalar(@sgs), '==', 1,           "message 11 still 1 group");
is($sgs[0]->type, 'Habeas-SWE');
ok($sgs[0]->habeasSweFieldsCorrect);

$swe->delete;
@sgs     = $head->spamGroups;
cmp_ok(scalar(@sgs), '==', 0,           "message 11 without spam group");
