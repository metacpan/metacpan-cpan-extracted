#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use Test::More;

BEGIN {
   use_ok 'MCE::Flow';
   use_ok 'MCE::Shared';
   use_ok 'MCE::Shared::Queue';
}

MCE::Flow->init(
   max_workers => 1
);

###############################################################################

## Queues must be shared first before anything else or it will not work.
## The reason is for the socket handles to be in place before starting the
## server. Sharing a hash or array will start the server automatically.

my $q1 = MCE::Shared->queue( type => $MCE::Shared::Queue::FIFO );
my $q2 = MCE::Shared->queue( type => $MCE::Shared::Queue::LIFO );
my $q;

## One must explicitly start the shared-server for condvars and queues.
## Not necessary otherwise when IO::FDPass is available.

MCE::Shared->start() unless $INC{'IO/FDPass.pm'};

###############################################################################

## https://sacred-texts.com/cla/usappho/sph02.htm (V)

my $sappho_text =
  "κὤττι μοι μάλιστα θέλω γένεσθαι
   μαινόλᾳ θύμῳ, τίνα δηὖτε πείθω
   μαῖσ ἄγην ἐσ σὰν φιλότατα τίσ τ, ὦ
   Πσάπφ᾽, ἀδίκηει;" . "Ǣ";

my $translation =
  "What in my mad heart was my greatest desire,
   Who was it now that must feel my allurements,
   Who was the fair one that must be persuaded,
   Who wronged thee Sappho?";

sub check_clear {
   my ($description) = @_;
   is( scalar(@{ $q->_get_aref() }), 0, $description );
}

sub check_enqueue {
   my ($description) = @_;
   is( join('', @{ $q->_get_aref() }), '12345', $description );
}

sub check_insert {
   my ($description, $expected) = @_;
   is( join('', @{ $q->_get_aref() }), $expected, $description );
}

sub check_pending {
   my ($description, $pending) = @_;
   is( $pending, 14, $description );
}

sub check_unicode_in {
   my ($description) = @_;
   is( join('', @{ $q->_get_aref() }), $sappho_text, $description );
}

sub check_unicode_out {
   my ($description, $value) = @_;
   is( $value, $sappho_text, $description );
}

sub check {
   my ($description, $expected, $value) = @_;
   is( $value, $expected, $description );
}

###############################################################################

##  FIFO tests

$q = $q1;

sub check_dequeue_fifo {
   my (@r) = @_;
   is( join('', @r), '1234', 'fifo, check dequeue' );
   is( join('', @{ $q->_get_aref() }), '5', 'fifo, check array' );
}

mce_flow sub {
   my ($mce) = @_;
   my $w; # effect is waiting for the check (MCE->do) to complete

   $q->enqueue('1', '2');
   $q->enqueue('3');
   $q->enqueue('4', '5');

   $w = MCE->do('check_enqueue', 'fifo, check enqueue');

   my @r = $q->dequeue(2);
   push @r, $q->dequeue;
   push @r, $q->dequeue(1); # Dequeue 1 explicitly

   $w = MCE->do('check_dequeue_fifo', @r);

   $q->clear;

   $w = MCE->do('check_clear', 'fifo, check clear');

   $q->enqueue('a', 'b', 'c', 'd');

   $q->insert(  1, 'e', 'f');
   $q->insert(  3, 'g');
   $q->insert( -2, 'h');
   $q->insert(  7, 'i');
   $q->insert(  9, 'j');
   $q->insert( 20, 'k');
   $q->insert(-10, 'l');
   $q->insert(-12, 'm');
   $q->insert(-20, 'n');

   $w = MCE->do('check_insert',  'fifo, check insert', 'nmalefgbhcidjk');
   $w = MCE->do('check_pending', 'fifo, check pending', $q->pending());

   $w = MCE->do('check', 'fifo, check peek at head     ',   'n', $q->peek(   ));
   $w = MCE->do('check', 'fifo, check peek at index   0',   'n', $q->peek(  0));
   $w = MCE->do('check', 'fifo, check peek at index   2',   'a', $q->peek(  2));
   $w = MCE->do('check', 'fifo, check peek at index  13',   'k', $q->peek( 13));
   $w = MCE->do('check', 'fifo, check peek at index  20', undef, $q->peek( 20));
   $w = MCE->do('check', 'fifo, check peek at index  -2',   'j', $q->peek( -2));
   $w = MCE->do('check', 'fifo, check peek at index -13',   'm', $q->peek(-13));
   $w = MCE->do('check', 'fifo, check peek at index -14',   'n', $q->peek(-14));
   $w = MCE->do('check', 'fifo, check peek at index -15', undef, $q->peek(-15));
   $w = MCE->do('check', 'fifo, check peek at index -20', undef, $q->peek(-20));

   $q->clear;

   $q->enqueue($sappho_text);
   $w = MCE->do('check_unicode_in',  'fifo, check unicode enqueue');
   $w = MCE->do('check_unicode_out', 'fifo, check unicode dequeue', $q->dequeue);

   $q->insert(0, $sappho_text);
   $w = MCE->do('check_unicode_out', 'fifo, check unicode peek', $q->peek(0));
   $w = MCE->do('check_unicode_out', 'fifo, check unicode insert', $q->dequeue_nb);

   $q->enqueue($sappho_text);
   $w = MCE->do('check_unicode_out', 'fifo, check unicode dequeue_timed', $q->dequeue_timed);

   return;
};

MCE::Flow->finish;

###############################################################################

##  LIFO tests

$q = $q2;

sub check_dequeue_lifo {
   my (@r) = @_;
   is( join('', @r), '5432', 'lifo, check dequeue' );
   is( join('', @{ $q->_get_aref() }), '1', 'lifo, check array' );
}

mce_flow sub {
   my ($mce) = @_;
   my $w; # effect is waiting for the check (MCE->do) to complete

   $q->enqueue('1', '2');
   $q->enqueue('3');
   $q->enqueue('4', '5');

   $w = MCE->do('check_enqueue', 'lifo, check enqueue');

   my @r = $q->dequeue(2);
   push @r, $q->dequeue;
   push @r, $q->dequeue(1); # Dequeue 1 explicitly

   $w = MCE->do('check_dequeue_lifo', @r);

   $q->clear;

   $w = MCE->do('check_clear', 'lifo, check clear');

   $q->enqueue('a', 'b', 'c', 'd');

   $q->insert(  1, 'e', 'f');
   $q->insert(  3, 'g');
   $q->insert( -2, 'h');
   $q->insert(  7, 'i');
   $q->insert(  9, 'j');
   $q->insert( 20, 'k');
   $q->insert(-10, 'l');
   $q->insert(-12, 'm');
   $q->insert(-20, 'n');

   $w = MCE->do('check_insert',  'lifo, check insert', 'kjaibhcgefldmn');
   $w = MCE->do('check_pending', 'lifo, check pending', $q->pending());

   $w = MCE->do('check', 'lifo, check peek at head     ',   'n', $q->peek(   ));
   $w = MCE->do('check', 'lifo, check peek at index   0',   'n', $q->peek(  0));
   $w = MCE->do('check', 'lifo, check peek at index   2',   'd', $q->peek(  2));
   $w = MCE->do('check', 'lifo, check peek at index  13',   'k', $q->peek( 13));
   $w = MCE->do('check', 'lifo, check peek at index  20', undef, $q->peek( 20));
   $w = MCE->do('check', 'lifo, check peek at index  -2',   'j', $q->peek( -2));
   $w = MCE->do('check', 'lifo, check peek at index -13',   'm', $q->peek(-13));
   $w = MCE->do('check', 'lifo, check peek at index -14',   'n', $q->peek(-14));
   $w = MCE->do('check', 'lifo, check peek at index -15', undef, $q->peek(-15));
   $w = MCE->do('check', 'lifo, check peek at index -20', undef, $q->peek(-20));

   $q->clear;

   $q->enqueue($sappho_text);
   $w = MCE->do('check_unicode_in',  'lifo, check unicode enqueue');
   $w = MCE->do('check_unicode_out', 'lifo, check unicode dequeue', $q->dequeue);

   $q->insert(0, $sappho_text);
   $w = MCE->do('check_unicode_out', 'lifo, check unicode peek', $q->peek(0));
   $w = MCE->do('check_unicode_out', 'lifo, check unicode insert', $q->dequeue_nb);

   $q->enqueue($sappho_text);
   $w = MCE->do('check_unicode_out', 'lifo, check unicode dequeue_timed', $q->dequeue_timed);

   return;
};

MCE::Flow->finish;

done_testing;

