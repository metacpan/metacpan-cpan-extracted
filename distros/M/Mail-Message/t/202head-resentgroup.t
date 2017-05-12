#!/usr/bin/env perl
#
# Test the processing of resent groups.
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Head::ResentGroup;
use Mail::Message::Head::Complete;

use Test::More tests => 26;
use IO::Scalar;

#
# Creation of a group
#

my $h = Mail::Message::Head::Complete->new;
ok(defined $h);

my $rg = Mail::Message::Head::ResentGroup->new
 ( head     => $h
 , From     => 'the.rg.group@example.com'
 , Received => 'obligatory field'
 );

ok(defined $rg);
isa_ok($rg, 'Mail::Message::Head::ResentGroup');

my @fn = $rg->fieldNames;
cmp_ok(scalar(@fn), '==', 2,           "Two fields");
is($fn[0], 'Received');
is($fn[1], 'Resent-From');

{  my $from = $rg->from;
   ok(ref $from);
   isa_ok($from, 'Mail::Message::Field');
   is($from->name, 'resent-from');
}

#
# Interaction with a header
#

$h->add(From => 'me');
$h->add(To => 'you');
$h->addResentGroup($rg);

{  my $output;
   my $fh = IO::Scalar->new(\$output);
   $h->print($fh);
   $fh->close;

   is($output, <<'EXPECTED');
From: me
To: you
Received: obligatory field
Resent-From: the.rg.group@example.com

EXPECTED

}

my $rg2 = $h->addResentGroup
 ( Received => 'now or never'
 , Cc            => 'cc to everyone'
 , Bcc           => 'undisclosed'
 , 'Return-Path' => 'Appears before everything else'
 , 'Message-ID'  => '<my own id>'
 , Sender        => 'do not believe it'
 , From          => 'should be added'
 , To            => 'just to check every single field'
 );

ok(defined $rg2);
ok(ref $rg2);
isa_ok($rg2, 'Mail::Message::Head::ResentGroup');

{  my $output;
   my $fh = IO::Scalar->new(\$output);
   $h->print($fh);
   $fh->close;

   is($output, <<'EXPECTED');
From: me
To: you
Return-Path: Appears before everything else
Received: now or never
Resent-From: should be added
Resent-Sender: do not believe it
Resent-To: just to check every single field
Resent-Cc: cc to everyone
Resent-Bcc: undisclosed
Resent-Message-ID: <my own id>
Received: obligatory field
Resent-From: the.rg.group@example.com

EXPECTED
}

my $h2 = $h->clone;
ok(defined $h2);
isa_ok($h2, 'Mail::Message::Head::Complete');

{  my @rgs = $h2->resentGroups;
   cmp_ok(@rgs, '==', 2);
   ok(defined $rgs[0]);
   ok(ref $rgs[0]);
   ok($rgs[0]->isa('Mail::Message::Head::ResentGroup'));

   my $rg1 = $rgs[0];
   is($rg1->messageId, '<my own id>');

   my @of  = $rg1->orderedFields;
   cmp_ok(@of, '==', 8);

   @of     = $rgs[1]->orderedFields;
   cmp_ok(@of, '==', 2);

   # Now delete, and close scope to avoid accidental reference to
   # fields which should get cleaned-up.
   $rgs[0]->delete;
}

{  my @rgs = $h2->resentGroups;
   cmp_ok(@rgs, '==', 1);

   my @of  = $rgs[0]->orderedFields;
   cmp_ok(@of, '==', 2);

   my $output;
   my $fh = IO::Scalar->new(\$output);
   $h2->print($fh);
   $fh->close;

   is($output, <<'EXPECTED');
From: me
To: you
Received: obligatory field
Resent-From: the.rg.group@example.com

EXPECTED

}
