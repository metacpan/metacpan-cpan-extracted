#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 32;

# Use the module
BEGIN {
	use_ok('Lingua::Phonology::Segment');
}
no warnings 'Lingua::Phonology::Segment';

# prepare
use Lingua::Phonology::Features;
use Lingua::Phonology::Symbols;
my $feat1 = new Lingua::Phonology::Features;
$feat1->loadfile('t/test.xml');
my $feat2 = new Lingua::Phonology::Features;
$feat2->loadfile('t/test.xml');
my $sym = Lingua::Phonology::Symbols->new($feat1);
# $sym->loadfile;

#############################
#	BASICS                  #
#############################
# new as class method
my $seg = Lingua::Phonology::Segment->new(new Lingua::Phonology::Features);
ok(UNIVERSAL::isa($seg, 'Lingua::Phonology::Segment'), 'new as class method');

# new as object method
my $nother = $seg->new($seg->featureset);
ok(UNIVERSAL::isa($seg, 'Lingua::Phonology::Segment'), 'new as object method');

# failure on no featureset
ok((not Lingua::Phonology::Segment->new()), 'failure on no featureset');

# failure on bad feaureset
ok((not $seg->new($sym)), 'failure on bad featureset');

# get/set featureset and symbolset
ok(UNIVERSAL::isa($seg->featureset, 'Lingua::Phonology::Features'), 'get featureset');

ok($seg->featureset($feat2) && ($seg->featureset eq $feat2), 'set featureset');

ok($seg->symbolset($sym) && ($seg->symbolset eq $sym), 'set symbols');

#############################
#   VALUE ET AL             #
#############################
# assign values and test return
# true values
$seg->binary(1); # assign via name
is($seg->value('binary'), 1, 'true value with value()');
is($seg->value_text('binary'), '+', 'true value with value_text()');
is(${$seg->value_ref('binary')}, 1, 'true value with value_ref()');

# false values
$seg->binary(0);
is($seg->value('binary'), 0, 'false value with value()');
is($seg->value_text('binary'), '-', 'false value with value_text()');
is(${$seg->value_ref('binary')}, 0, 'false value with value_ref()');

# test nodes
is(ref($seg->value('Child 2')), 'HASH', 'return value from node');
ok($seg->value('Child 2', undef, {binary=>1}), 'assign to node');
is(${$seg->value_ref('Child 2')->{binary}->[0]}, 1, 'keys of node hashref from value_ref()');
is($seg->value('Child 2')->{binary}->[0], 1, 'keys of node hashref from value()');
is($seg->value_text('Child 2')->{binary}->[0], '+', 'keys of node hashref from value_text()');

# test assigning equivalent refs
my $seg2 = $seg->new($feat2);
$seg2->binary($seg->value_ref('binary'));
is($seg2->value_ref('binary'), $seg->value_ref('binary'), 'assign references assignment');

# break equiv refs w/ new ref
my $new = 1;
$seg2->binary(\$new);
isnt $seg2->value_ref('binary'), $seg->value_ref('binary'), 'break reference assignment';
eval { $seg->binary(\0) };
is $seg->binary, 0, 'assign reference to literal';


#############################
#	MISCELLANEOUS           #
#############################
# basic all_values
$seg->clear;
$seg->privative(1);
$seg->binary(0);
my %vals = $seg->all_values;
ok(($vals{privative} eq 1 &&
	$vals{binary} eq 0 &&
	not exists($vals{scalar})),
	'all_values() in list context');

my $vals = $seg->all_values;
is_deeply \%vals, $vals, 'all_values in scalar context';

{
    # Get something in both list and scalar context
    my @trash = $seg->ROOT;
    my $trash = $seg->ROOT;
    is_deeply \%vals, { $seg->all_values }, 'all_values unchanged after getting value';
}

# delinking
ok($seg->delink('privative'), 'delink()');

# all_values after delinking
%vals = $seg->all_values;
ok((not exists $vals{privative}), 'all_values() after delink()');

# normal spell (needs some preparation)
$feat1->loadfile;
$sym->loadfile;
$seg->featureset($feat1);
$seg->labial(1) && $seg->voice(1) && $seg->continuant(0);
is($seg->spell, 'b', 'successfull spell()');

# failure of spell
my $seg3 = Lingua::Phonology::Segment->new($feat2);
ok((not $seg3->spell), 'failure of spell()');

# duplicate
my $copy = $seg->duplicate;
is_deeply { $seg->all_values }, { $copy->all_values }, 'proper duplication';
isnt int $seg, int $copy, 'duplicate is different ref';

# clear
$seg->clear;
ok((not keys %{$seg->all_values}), 'clear()');
