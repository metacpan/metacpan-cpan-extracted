#!/usr/bin/perl -w

use strict;
use Test;
BEGIN {plan tests => 8};

use List::Indexed;

use File::Basename;
use lib dirname($0);
use TestLib;

use vars qw(@testList);

################################################################################

@testList = (	
	{'name'=>'one', 	'value'=> 1}, 
	{'name'=>'two', 	'value'=> 2}, 
	{'name'=>'three',	'value'=> 3}
);


TEST1: # add/remove (size)
{ 
	my $list = new List::Indexed;
	if ($list->size() != 0 || ! $list->empty()) {
		ok(0);
		last TEST1;
	}

	$list->add('one', 1);
	$list->add('two', 2);
	$list->add('three', 3);	
	if ($list->size() != 3) {
		ok(0);
		last TEST1;
	}

	$list->remove();
	if ($list->size() != 2) {
		ok(0);
		last TEST1;
	}

	$list->remove();
	$list->remove();
	$list->remove(); # on empty list
	if ($list->size() != 0) {
		ok(0);
		last TEST1;
	}
	ok(1);
}


TEST2: # add/remove (content)
{
	my $list = new List::Indexed;

	$list->add('one', 1);
	$list->add('two', 2);
	$list->add('three', 3);	

	my @readList;
	my ($key, $element) = $list->remove();
	push(@readList, {'name'=>$key, 'value'=>$element});
	($key, $element) = $list->remove();
	push(@readList, {'name'=>$key, 'value'=>$element});
	($key, $element) = $list->remove();
	push(@readList, {'name'=>$key, 'value'=>$element});

	if (! compare_structure(\@testList, \@readList)) {
		ok(0);
		last TEST2;
	}
	ok(1);
}


TEST3: # iterate over the list
{
	my $list = new List::Indexed;

	$list->add('one', 1);
	$list->add('two', 2);
	$list->add('three', 3);	

	my @readList;
	my ($key, $element) = $list->read();
	push(@readList, {'name'=>$key, 'value'=>$element});
	($key, $element) = $list->read();
	push(@readList, {'name'=>$key, 'value'=>$element});
	($key, $element) = $list->read();
	push(@readList, {'name'=>$key, 'value'=>$element});

	($key, $element) = $list->read(); # on empty list
	if (defined $key) {
		push(@readList, {'name'=>$key, 'value'=>$element});
	}

	if (! compare_structure(\@testList, \@readList)) {
		ok(0);
		last TEST3;
	}
	ok(1);
}


TEST4: # re-iterate over the list
{
	my $list = new List::Indexed;

	$list->add('one', 1);
	$list->add('two', 2);
	$list->add('three', 3);	

	my @readList;
	$list->read();
	$list->read();

	$list->reset();
	
	my ($key, $element) = $list->read();
	push(@readList, {'name'=>$key, 'value'=>$element});
	($key, $element) = $list->read();
	push(@readList, {'name'=>$key, 'value'=>$element});
	($key, $element) = $list->read();
	push(@readList, {'name'=>$key, 'value'=>$element});

	if (! compare_structure(\@testList, \@readList)) {
		ok(0);
		last TEST4;
	}
	ok(1);
}


TEST5: # search elements using keys
{
	my $list = new List::Indexed;

	$list->add('one', 1);
	$list->add('two', 2);
	$list->add('three', 3);

	my $position = $list->find('two');
	my ($key, $element) = $list->read_at($position);
	if ($key ne 'two' || $element != 2) {
		ok(0);
		last TEST5;
	}

	$position = $list->find('not existing');
	if (defined $position) {
		ok(0);
		last TEST5;
	}
	($key, $element) = $list->read_at($position);
	if (defined $key || defined $element) {
		ok(0);
		last TEST5;
	}

	$element = $list->read('one');
	if ($element != 1) {
		ok(0);
		last TEST5;
	}

	$element = $list->read('not existing');
	if (defined $element) {
		ok(0);
		last TEST5;
	}

	ok(1);
}


TEST6: # identify and remove items
{
	my $list = new List::Indexed;

	$list->add('one', 1);
	$list->add('two', 2);
	$list->add('three', 3);

	my $position = $list->find('three');
	my ($key, $element) = $list->remove_at($position);
	my $size = $list->size();
	if ($key ne 'three' || $element != 3 || $size != 2) {
		ok(0);
		last TEST6;
	}

	$element = $list->remove('one');
	if ($element != 1) {
		ok(0);
		last TEST6;
	}

	($key, $element) = $list->remove();
	if ($key ne 'two' || $element != 2) {
		ok(0);
		last TEST6;
	}

	ok(1);
}


TEST7: # insert new elements in the list
{
	my $list = new List::Indexed;

	$list->add('one', 1);
	$list->add('two', 2);
	$list->add('three', 3);

	my $position = $list->find('two');
	$list->insert_at($position, "one and a half", 1.5);

	$position = $list->find('three');
	$list->insert_after($position, "three and a half", 3.5);

	$list->insert_after(100, "hundred", 100);

	$list->read();
	my ($key, $element) = $list->read();
	if ($key ne "one and a half" || $element != 1.5) {
		ok(0);
		last TEST7;
	}

	$list->read();
	$list->read();
	($key, $element) = $list->read();
	if ($key ne "three and a half" || $element != 3.5) {
		ok(0);
		last TEST7;
	}

	ok(1);
}


TEST8: # replace elements from the list
{	
	my $list = new List::Indexed;

	$list->add('one', 1);
	$list->add('two', 2);
	$list->add('three', 3);

	my $position = $list->find('two');
	$list->replace_at($position, 2.5);

	$list->replace('three', "THREE");
	
	my @readList;
	my ($key, $element) = $list->read();
	push(@readList, {'name'=>$key, 'value'=>$element});
	($key, $element) = $list->read();
	push(@readList, {'name'=>$key, 'value'=>$element});
	($key, $element) = $list->read();
	push(@readList, {'name'=>$key, 'value'=>$element});
	
	if (! compare_structure(\@readList, [
			{'name'=>'one' 		,'value'=> 1},
			{'name'=>'two' 		,'value'=> 2.5},
			{'name'=>'three'	,'value'=> "THREE"}]))
	{
		ok(0);
		last TEST8;
	}
	ok(1);
}
