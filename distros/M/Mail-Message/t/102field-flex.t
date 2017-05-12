#!/usr/bin/env perl
#
# Test processing of header-fields in flexible format: only single fields,
#  not whole headers.  This also doesn't cover reading headers from file.
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Field::Flex;

use Test::More tests => 44;
use Mail::Address;

#
# Processing unstructured lines.
#

my $a = Mail::Message::Field::Flex->new('A: B  ; C');
is($a->name, 'a');
is($a->body, 'B  ; C');
ok(not defined $a->comment);

# No folding permitted.

my $bbody = 'B  ; C234290iwfjoj w etuwou   toiwutoi wtwoetuw oiurotu 3 ouwout 2 oueotu2 fqweortu3';
my $b = Mail::Message::Field::Flex->new("A: $bbody");
my @lines = $b->toString(100);

cmp_ok(@lines, '==', 1);
is($lines[0], "A: $bbody\n");
is($b->body, $bbody);

@lines = $b->toString(40);
cmp_ok(@lines, '==', 3);
is($lines[2], " oueotu2 fqweortu3\n");

#
# Processing of structured lines.
#

my $f = Mail::Message::Field::Flex->new('Sender:  B ;  C');
is($f->name, 'sender');
is($f->body, 'B');
is($f, 'B ;  C');
like($f->comment, qr/^\s*C\s*/);

# No comment, strip CR LF

my $g = Mail::Message::Field::Flex->new("Sender: B\015\012");
is($g->body, 'B');
is($g->comment, '');

# Separate head and body.

my $h = Mail::Message::Field::Flex->new("Sender", "B\015\012");
is($h->body, 'B');
is($h->comment, '');

my $i = Mail::Message::Field::Flex->new('Sender', 'B ;  C');
is($i->name, 'sender');
is($i->body, 'B');
like($i->comment, qr/^\s*C\s*/);

my $j = Mail::Message::Field::Flex->new('Sender', 'B', [comment => 'C']);
is($j->name, 'sender');
is($j->body, 'B');
like($j->comment, qr/^\s*C\s*/);

# Check toString (for unstructured field, so no folding)

my $k = Mail::Message::Field::Flex->new(A => 'short line');
is($k->toString, "A: short line\n");
my @klines = $k->toString;
cmp_ok(@klines, '==', 1);

my $l = Mail::Message::Field::Flex->new(A =>
 'oijfjslkgjhius2rehtpo2uwpefnwlsjfh2oireuqfqlkhfjowtropqhflksjhflkjhoiewurpq');
my @llines = $k->toString;
ok(@llines==1); 

my $n  = Mail::Message::Field::Flex->new(A => 7);
my $x = $n + 0;
ok($n ? 1 : 0);
ok($x==7);
ok($n > 6);
ok($n < 8);
ok($n==7);
ok(6 < $n);
ok(8 > $n);

#
# Check gluing addresses
#

my @mb = Mail::Address->parse('me@localhost, you@somewhere.nl');
cmp_ok(@mb, '==', 2);
my $r  = Mail::Message::Field::Flex->new(Cc => $mb[0]);
is($r->toString, "Cc: me\@localhost\n");
$r     = Mail::Message::Field::Flex->new(Cc => \@mb);
is($r->toString, "Cc: me\@localhost, you\@somewhere.nl\n");

my $r2 = Mail::Message::Field::Flex->new(Bcc => $r);
is($r2->toString, "Bcc: me\@localhost, you\@somewhere.nl\n");

#
# Checking attributes
#

my $charset = 'iso-8859-1';
my $comment = qq(charset="iso-8859-1"; format=flowed);

my $p = Mail::Message::Field::Flex->new("Content-Type: text/plain; $comment");
is($p->comment, $comment);
is($p->body, 'text/plain');
is($p->attribute('charset'), $charset);

my $q = Mail::Message::Field::Flex->new('Content-Type: text/plain');
is($q->toString, "Content-Type: text/plain\n");
is($q->attribute(charset => 'iso-10646'), 'iso-10646');
is($q->attribute('charset'), 'iso-10646');
is($q->comment, 'charset="iso-10646"');
is($q->toString, qq(Content-Type: text/plain; charset="iso-10646"\n));
