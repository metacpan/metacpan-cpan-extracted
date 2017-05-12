#!/usr/bin/env perl
#
# Test the processing of a whole message header, not the reading of a
# header from file.
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Head::Complete;

use Test::More tests => 25;
use IO::Scalar;

my $h = Mail::Message::Head::Complete->new;
{  my @o = $h->names;
   cmp_ok(scalar @o, '==', 0);
}

# Adding a first.

{  my $a = $h->add(From => 'me@home');
   ok(ref $a);
   isa_ok($a, 'Mail::Message::Field');
}

{  my @o = $h->names;
   cmp_ok(@o, '==', 1);
}

{  my @f = $h->get('From'); # list context
   cmp_ok(@f, '==', 1);
   ok(ref $f[0]);
   isa_ok($f[0], 'Mail::Message::Field');
   is($f[0]->body, 'me@home');
}

{  my $f = $h->get('From'); # scalar context
   is($f->body, 'me@home');
}

# Adding a second.

$h->add(From => 'you2me');
{  my @o = $h->names;
   cmp_ok(@o, '==', 1);
}

{  my @f = $h->get('From'); # list context
   cmp_ok(@f, '==', 2);
   is($f[0]->body, 'me@home');
   is($f[1]->body, 'you2me');
}

{  my $f = $h->get('From'); # scalar context
   is($f->body, 'you2me');
}

# Missing

{  my @f = $h->get('unknown');
   cmp_ok(@f, '==', 0);
}

{  my $f = $h->get('unknown');
   ok(! defined $f);
}

# Set

{
   $h->set(From => 'perl');
   my @f = $h->get('From');
   cmp_ok(@f, '==', 1);
}

{  my @o = $h->names;
   cmp_ok(@o, '==', 1);
}

$h->set(New => 'test');
{  my @o = sort $h->names;
   cmp_ok(@o, '==', 2);
   is($o[0], 'from');
   is($o[1], 'new');
}

# Reset

$h->reset('From');
{  my @f = $h->get('From');
   cmp_ok(@f, '==', 0);
}

{
   my $l = Mail::Message::Field->new(New => 'other');
   $h->reset('NEW', $h->get('new'), $l);
}

{  my @f = $h->get('neW');
   cmp_ok(@f, '==', 2);
}

# Print

$h->add(Subject => 'hallo!');
$h->add(To => 'the world');
$h->add(From => 'me');

my $output;
my $fakefile = new IO::Scalar \$output;

$h->print($fakefile, 0);
my $expected = <<'EXPECTED_OUTPUT';
New: test
New: other
Subject: hallo!
To: the world
From: me

EXPECTED_OUTPUT

is($output, $expected);
is($h->toString, $expected);

$fakefile->close;
