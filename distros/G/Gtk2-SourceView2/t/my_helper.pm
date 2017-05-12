#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder;


#
# Check if an enum property can be set
#
sub is_enum_ok {
	# In Perl enums are like strings!
	return is_string_ok(@_);
}


#
# Check if an string property can be set
#
sub is_string_ok {
	my ($view, $property, $val1, $val2) = @_;
	my $get = "get_$property";
	my $set = "set_$property";
	my $value = $view->$get();
	my ($new_value) = ($value eq $val1 ? $val2 : $val1);
	$view->$set($new_value);
	my $tester = Test::Builder->new();
	$tester->is_eq($view->$get(), $new_value, $property);
}


#
# Check if an int property can be set
#
sub is_int_ok {
	my ($view, $property, $val1, $val2) = @_;
	my $get = "get_$property";
	my $set = "set_$property";

	my $value = $view->$get();
	my ($new_value) = ($value == $val1 ? $val2 : $val1);
	$view->$set($new_value);
	my $tester = Test::Builder->new();
	$tester->is_num($view->$get(), $new_value, $property);
}


#
# Check if a boolean property can be set
#
sub is_boolean_ok {
	my ($view, $property) = @_;
	my $get = "get_$property";
	my $set = "set_$property";

	my $value = $view->$get();
	$view->$set(! $value);
	my $tester = Test::Builder->new();
	$tester->is_eq($view->$get(), ! $value, $property);
}

1;
