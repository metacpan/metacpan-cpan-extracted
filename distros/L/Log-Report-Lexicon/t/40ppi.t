#!/usr/bin/env perl
# Try Extract PPI

use warnings;
use strict;

use File::Temp   qw/tempdir/;
use Test::More;

use constant MSGIDS => 25;
use constant PLURAL_MSGIDS => 4;

BEGIN
{   eval "require PPI";
    plan skip_all => 'PPI not installed'
        if $@;

    plan tests => 10 + MSGIDS*4 + PLURAL_MSGIDS*1;
    use_ok('Log::Report::Extract::PerlPPI');
}

my $lexicon    = tempdir CLEANUP => 1;

my %expect_pos = ('' => 1);  # expect header
sub take($@)
{   my $result = shift;
    ok("$result", "$result");
    $expect_pos{$_}++ for @_;
}

###

my $ppi = Log::Report::Extract::PerlPPI->new(lexicon => $lexicon);

ok(defined $ppi, 'created parser');
isa_ok($ppi, 'Log::Report::Extract::PerlPPI');

$ppi->process( __FILE__ );   # yes, this file!
$ppi->write;

my @potfns = $ppi->index->list('first-domain');
cmp_ok(scalar @potfns, '==', 1, "one file created");
my $potfn = shift @potfns;
ok(defined $potfn);
ok(-s $potfn, "produced file $potfn has size");

####

sub dummy($) {shift}

use Log::Report 'first-domain';  # cannot use variable textdomain
take("a0");
take(__"a1", 'a1');
take((__"a2"), 'a2');
take((__"a3a", "a3b"), 'a3a');
take(__("a4"), 'a4');
take(__ dummy('a7'));
take(__ dummy 'a8');
take(__(dummy 'a9'));

take((__x"b2"), 'b2');
take((__x"b3a", b2b => "b3c"), 'b3a');
take(__x("b4"), 'b4');
take(__x("b5a", b5b => "b5c"), 'b5a');
take(__x('b6a', b6b => "b6c"), 'b6a');
take(__x(qq{b7a}, b7b => "b7c"), 'b7a');
take(__x(q{b8a}, b8b => "b8c"), 'b8a');
take(__x(b9a => b9b => "b9c"), 'b9a');
take(__x(b10 => 1, 2), 'b10');

take((__n "c1", "c2", 1), "c1", "c2");
take((__n "c3", "c4", 0), "c3", "c4");
take(__n("c5", "c6", 1), "c5", "c6");
take(__n("c7", "c8", 0), "c7", "c8");

take(N__("d1"), "d1", "d1");

take(join(',', N__w("d2 d3")), "d2", "d3");
take(join(',', N__w("  d4 	d5 
 d6
d7")), "d4", "d5", "d6", "d7");  # line contains tab

### do not index these:

__x(+"e1");

### check that all tags were found in POT

my $pot = Log::Report::Lexicon::POT->read($potfn, charset => 'utf-8');
ok(defined $pot, 'read translation table');
my @pos = $pot->translations('ACTIVE');
ok(@pos > 0);
cmp_ok(scalar @pos, '==', MSGIDS, 'correct number tests');
cmp_ok(scalar @pos, '==', scalar $pot->translations); # all active

my %msgids;
for my $po (@pos)
{   my $msgid = $po->msgid;
    ok(defined $msgid, "processing $msgid");
    ok(!defined $msgids{$msgid}, 'check not double');
    $msgids{$msgid}++;
    ok(delete $expect_pos{$msgid}, "was expected $msgid");

    my $plural = $po->plural
        or next;
    ok(delete $expect_pos{$plural}, 'plural was expected');
}

cmp_ok(scalar keys %expect_pos, '==', 0, "all msgids found");
warn "NOT FOUND: $_\n" for keys %expect_pos;
