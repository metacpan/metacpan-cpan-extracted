#!/usr/local/bin/perl

use Test::More tests => 6;
BEGIN { use_ok('Loop') };

use warnings;
use strict;

use Data::Dumper;

############################################################################
# given two arrays, which are both order dependent and interrelated,
# create a hash using Array::Loop which converts first array to second array
# this will test index, value, and map return value
############################################################################
my @military = qw(alpha	bravo	charlie	delta	echo	foxtrot);
my @civilian = qw(alice	bob	charlie	dave	eve	frank);

my %mil_to_civ;
%mil_to_civ = Loop::Array @military, sub
	{
	my ($index,$mil_val)=@_;
	return($mil_val, $civilian[$index]);
	};

my %expected_mil_to_civ = 
	qw(
	alpha	alice
	bravo	bob
	charlie	charlie
	delta	dave
	echo	eve
	foxtrot	frank
	);

is_deeply( \%mil_to_civ, \%expected_mil_to_civ, 
	"Loop::Array, index,value,map");

############################################################################
# test the loop WITHOUT a "map" return value;
############################################################################
my @generated_array;

Loop::Array @military, sub
	{
	my ($index,$value)=@_;
	push(@generated_array,$value);
	};

is_deeply( \@generated_array, \@military, 
	"Loop::Array, non-mapping loop");

############################################################################
# test flow control 'last'
############################################################################
my @last_array = Loop::Array @military, sub
	{
	my($index,$value)=@_;
	if($index==3)
		{
		$_[-1]='last';
		return;
		}
	return $value;
	};

my @expected_last_array = qw ( alpha bravo charlie );

is_deeply( \@last_array, \@expected_last_array, 
	"Loop::Array, 'last' flow control");

############################################################################
# test index reassignment
############################################################################
my @index_array = Loop::Array @military, sub
	{
	my($index,$value)=@_;
	if($index==1)
		{
		$_[0]=4;
		return;
		}
	return $value;
	};

my @expected_index_array = qw ( alpha  foxtrot );

is_deeply( \@index_array, \@expected_index_array, 
	"Loop::Array, index numeric reassignment");

############################################################################
# test value reassignment,
# THIS REASSIGNS THE VALUE OF ORIGINAL ARRAY
# SO YOU SHOULDN"T USE @MILITARY AFTER THIS, KNOWING ITS NOT THE
# STANDARD PHONETIC ALPHABET ANYMORE.
############################################################################
Loop::Array @military, sub
	{
	my($index,$value)=@_;

	# if civilian and military are same values,
	# mark the original military value with the string 'SAME'
	if($value eq $civilian[$index])
		{
		$_[1] = 'SAME'; 
		}
	};

my @expected_military = qw ( alpha bravo SAME delta echo foxtrot );

is_deeply( \@military, \@expected_military, 
	"Loop::Array, original array value reassignment");

############################################################################
# done
############################################################################


