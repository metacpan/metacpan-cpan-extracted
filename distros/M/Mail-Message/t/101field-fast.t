#!/usr/bin/env perl
#
# Test processing of header-fields with Mail::Message::Field::Fast.
# Only single fields, not whole headers. This also doesn't cover reading
# headers from file.
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Field::Fast;

use Test::More tests => 72;
use Mail::Address;

#
# Processing unstructured lines.
#

my $a = Mail::Message::Field::Fast->new('A: B  ; C');
is($a->name, 'a');
is($a->body, 'B  ; C');
ok(not defined $a->comment);

# No folding permitted.

my $b1 = ' B  ; C234290iwfjoj w etuwou   toiwutoi';
my $b2 = ' wtwoetuw oiurotu 3 ouwout 2 oueotu2';
my $b3 = ' fqweortu3';
my $bbody = "$b1$b2$b3";

my $b = Mail::Message::Field::Fast->new("A: $bbody");
my @lines = $b->toString(100);
cmp_ok(@lines, '==', 1);
is($lines[0], "A:$bbody\n");

@lines = $b->toString(42);
cmp_ok(@lines, '==', 3);
is($lines[0], "A:$b1\n");
is($lines[1], "$b2\n");
is($lines[2], "$b3\n");
is(' '.$b->body, $bbody);

#
# Processing of structured lines.
#

my $f = Mail::Message::Field::Fast->new('Sender:  B ;  C');
ok($f->isStructured);
is($f->name, 'sender');
is($f->body, 'B');
is($f, 'B ;  C');
is($f->comment, 'C');

# No comment, strip CR LF

my $g = Mail::Message::Field::Fast->new("Sender: B\015\012\n");
is($g->body, 'B');
is($g->comment, '');

# Separate head and body.

my $h = Mail::Message::Field::Fast->new("Sender", "B\015\012\n");
is($h->body, 'B');
is($h->comment, '');

my $i = Mail::Message::Field::Fast->new('Sender', 'B ;  C');
is($i->name, 'sender');
is($i->body, 'B');
like($i->comment, qr/^\s*C\s*/);

my $j = Mail::Message::Field::Fast->new('Sender', 'B', 'C');
is($j->name, 'sender');
is($j->body, 'B');
like($j->comment, qr/^\s*C\s*/);

# Check toString (for unstructured field, so no folding)

my $k = Mail::Message::Field::Fast->new(A => 'short line');
is($k->toString, "A: short line\n");
my @klines = $k->toString;
cmp_ok(@klines, '==', 1);

my $l = Mail::Message::Field::Fast->new(A =>
 'oijfjslkgjhius2rehtpo2uwpefnwlsjfh2oireuqfqlkhfjowtropqhflksjhflkjhoiewurpq');
my @llines = $k->toString;
cmp_ok(@llines, '==', 1); 

my $m = Mail::Message::Field::Fast->new(A =>
  'roijfjslkgjhiu, rehtpo2uwpe, fnwlsjfh2oire, uqfqlkhfjowtrop, qhflksjhflkj, hoiewurpq');

my @mlines = $m->toString;
cmp_ok(@mlines, '==', 2);
is($mlines[1], " hoiewurpq\n");

my $n  = Mail::Message::Field::Fast->new(A => 7);
my $x = $n + 0;
ok($n ? 1 : 0);
ok($x==7);
ok($n > 6);
ok($n < 8);
cmp_ok($n, '==', 7);
ok(6 < $n);
ok(8 > $n);

#
# Check gluing addresses
#

my @mb = Mail::Address->parse('me@localhost, you@somewhere.nl');
cmp_ok(scalar @mb, '==', 2);
my $r  = Mail::Message::Field::Fast->new(Cc => $mb[0]);
is($r->toString, "Cc: me\@localhost\n");

$r     = Mail::Message::Field::Fast->new(Cc => \@mb);
is($r->toString, "Cc: me\@localhost, you\@somewhere.nl\n");

my $r2 = Mail::Message::Field::Fast->new(Bcc => $r);
is($r2->toString, "Bcc: me\@localhost, you\@somewhere.nl\n");

#
# Checking attributes
#

my $charset = 'iso-8859-1';
my $comment = qq(charset="iso-8859-1"; format=flowed);

my $p = Mail::Message::Field::Fast->new("Content-Type: text/plain; $comment");
is($p->comment, $comment);
is($p->body, 'text/plain');
is($p->attribute('charset'), $charset);
is($p->attribute('format'), 'flowed');
ok(!defined $p->attribute('boundary'));
is($p->attribute(charset => 'us-ascii'), 'us-ascii');
is($p->attribute('charset'), 'us-ascii');
is($p->comment, 'charset="us-ascii"; format=flowed');
is($p->attribute(format => 'newform'), 'newform');
is($p->comment, 'charset="us-ascii"; format="newform"');
is($p->attribute(newfield => 'bull'), 'bull');
is($p->attribute('newfield'), 'bull');
is($p->comment, 'charset="us-ascii"; format="newform"; newfield="bull"');

my %attrs = $p->attributes;
cmp_ok(keys %attrs, '==', 3, "list of attributes");
is($attrs{charset}, 'us-ascii');
is($attrs{format}, 'newform');
is($attrs{newfield}, 'bull');

my $q = Mail::Message::Field::Fast->new('Content-Type: text/plain');
is($q->toString, "Content-Type: text/plain\n");
is($q->attribute(charset => 'iso-10646'), 'iso-10646');
is($q->attribute('charset'), 'iso-10646');
is($q->comment, 'charset="iso-10646"');
is($q->toString, qq(Content-Type: text/plain; charset="iso-10646"\n));

#
# Check preferred capitization of Labels
#

my @tests =
( 'Content-Transfer-Encoding' => 'Content-Transfer-Encoding'
, 'content-transfer-encoding' => 'Content-Transfer-Encoding'
, 'CONTENT-TRANSFER-ENCODING' => 'Content-Transfer-Encoding'
, 'cONTENT-tRANSFER-eNCODING' => 'Content-Transfer-Encoding'
, 'mime-version'              => 'MIME-Version'
, 'MIME-VERSION'              => 'MIME-Version'
, 'Mime-vERSION'              => 'MIME-Version'
, 'src-label'                 => 'SRC-Label'
, 'my-src-label'              => 'My-SRC-Label'
);

while(@tests)
{   my ($from, $to) = (shift @tests, shift @tests);
    is(Mail::Message::Field->wellformedName($from), $to);
}

