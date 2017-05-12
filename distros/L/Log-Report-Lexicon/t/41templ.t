#!/usr/bin/env perl
# Try Extract templates

use warnings;
use strict;

use File::Temp   qw/tempdir/;

use Test::More;

use Log::Report;  # mode => 'DEBUG';
use Log::Report::Lexicon::POT;
use Log::Report::Extract::Template;

use constant MSGIDS => 12;

# see after __END__
my @expect_pos = split /\n/, <<'_EXPECT';
first
second
third
fourth
fifth
six six six
%d seven
eight
nine
tenth
{a} eleven
twelve {b}
_EXPECT

chomp $expect_pos[-1];
cmp_ok(scalar @expect_pos, '==', MSGIDS);
my %expect_pos = map { ($_ => 1) } @expect_pos;
$expect_pos{''} = 1;  # header

BEGIN {
   plan tests => 15 + MSGIDS*3;
}

my $lexicon = tempdir CLEANUP => 1;

my $extr = Log::Report::Extract::Template->new
 ( lexicon => $lexicon
 , domain  => 'my-domain'
 , pattern => 'TT2-loc'
 );

ok(defined $extr, 'created parser');
isa_ok($extr, 'Log::Report::Extract::Template');

my $found = $extr->process( __FILE__ );   # yes, this file!
cmp_ok($found, '==', MSGIDS);

$extr->write;

my @potfns = $extr->index->list('my-domain');
cmp_ok(scalar @potfns, '==', 1, "one file created");
my $potfn = shift @potfns;
ok(defined $potfn);
ok(-s $potfn, "produced file $potfn has size");

#system "cat $potfn";

my $pot = Log::Report::Lexicon::POT->read($potfn, charset => 'utf-8');
ok(defined $pot, 'read translation table');
my @pos = $pot->translations('ACTIVE');
ok(@pos > 0);

# (+1 for the header)
cmp_ok(scalar @pos, '==', MSGIDS+1, 'correct number tests');
cmp_ok(scalar @pos, '==', scalar $pot->translations); # all active

my %msgids;
for my $po (@pos)
{   my $msgid = $po->msgid;
    ok(defined $msgid, "processing '$msgid'");
    ok(!defined $msgids{$msgid}, 'check not double');
    $msgids{$msgid}++;
    ok(delete $expect_pos{$msgid}, 'was expected');
}

cmp_ok(scalar keys %expect_pos, '==', 0, "all msgids found");
warn "NOT FOUND: $_\n" for keys %expect_pos;

__END__
Here, the example template starts
[%loc("first")%]
[%loc("second")%]
[%loc('third')%]
[% loc ( 'fourth' ) %]
   [%
   loc
   (
   'fifth'
   , params
   )
   %]
[%xloc('not found')%]
[%loc('six six six')%]
[% loc('%d seven|%d sevens', 7) %]
[% INCLUDE header.tt
   title = loc("eight") loc  ('nine'  )
   css   =loc( 'tenth' )
%]

[% '{a} eleven' | loc(a => 3) %]
[%| loc(b=>4) %]twelve {b}[%END%]
