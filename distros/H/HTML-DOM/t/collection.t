#!/usr/bin/perl -T

# The HTMLCollection interface

use strict; use warnings;

use Test::More tests => 32;


# -------------------------#
# Tests 1-2: load the modules

BEGIN { use_ok 'HTML::DOM::Collection'; }
BEGIN { use_ok 'HTML::DOM::NodeList'; }

# -------------------------#
# Test 3: constructor

my (@array);

my $col = new HTML::DOM::Collection (
	new HTML::DOM::NodeList \@array
);
isa_ok $col, 'HTML::DOM::Collection';

{package _Elem;
 sub id { defined ${$_[0]}[0] ? reverse ${$_[0]}[0] : undef}
 sub attr { return ${$_[0]}[0] if $_[1] eq 'name'}
 sub tag { 'a' } }
@array = map +(bless[$_],'_Elem'),
	qw'Able was I ere I saw Elba', undef;

# -------------------------#
# Tests 4-15: access contents

is +(item $col 3)->id, 'ere', 'item';
is $$col[3]->id, 'ere', 'array overloading';
is $col->length, 8, 'length';
is $col->namedItem('saw')->id, 'saw', 'namedItem (id overrides name)';
is $col->namedItem('Able')->id, 'elbA',
	'namedItem (name works nonetheless)';
is $col->namedItem('I'), $col->[2],
	'The first item is chosen if two share the same name.';
is $col->{Elba}, $col->namedItem('Elba'), 'hash overloading';

ok exists $col->{Elba}, 'exists';
ok!exists $col->{eLba}, 'doesn\'t exist';
is_deeply[keys %$col], [qw[elbA saw I ere was ablE Able Elba]], 'keys';
# implementation detail (subject to change): FIRSTKEY and NEXTKEY iterate
# through the items checking the IDs first, then they go through the list
# again, getting names.
ok %$col, 'hash in scalar context';
{
	my @copy = @array ; @array = ();
	ok!%$col, 'empty hash in scalar context';
	@array = @copy;
}

# -------------------------#
# Tests 16-17: access contents after modification

splice @array, 1,1;

is +(item $col 2)->id, 'ere', 'item after modification';
is +(namedItem $col 'saw')->attr('name'), 'saw',
	'namedItem afer modification';

# -------------------------#
# Tests 13-31: different types of named elements

sub _elem2::id { }
sub _elem2::attr { $_[0][1] }
sub _elem2::tag { $_[0][0] }

{
	my @nameable_elems = qw/ button textarea applet select form frame
	                         iframe img a input object map param meta/;
	@array = map bless([$_ => "$_-1"], '_elem2'),@nameable_elems;
	my $count = 0;
	is $col->namedItem("$_-1"), $array[$count++],
		"namedItem can return a" . 'n' x /^[aio]/ . " $_ element"
		for @nameable_elems;
}

# -------------------------#
# Test 32: rubbish disposal

use Scalar::Util 'weaken';
weaken $col;
is $col, undef, 'rubbish disposal';

