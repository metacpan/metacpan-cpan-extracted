#!/usr/bin/perl

package Goo::Thing::tpm::Tester;

###############################################################################
# Turbo10.com
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:   	Nigel Hamilton
# Filename: 	Goo::Thing::tpm::Tester.pm
# Description:  Test things.
#
# Date      	Change
# -----------------------------------------------------------------------------
# 08/02/2005    Auto generated file
# 08/02/2005    Needed an automate test generator and suite
#       		Encounter evil namespace clash when called "Test.pm" - decided
#       		to rename it "Tester.pm"
# 09/02/2005    Added prototype to test to stop slurpy array side effects
#
###############################################################################

use strict;

#use Maths;
use Goo::Object;

# use Logger;
use Goo::Prompter;

# Test isa Object
use base qw(Goo::Object);


###############################################################################
#
# new - construct a goo object
#
###############################################################################

sub new {

    my ($class, $filename) = @_;

    my $this = $class->SUPER::new();

    # strip any suffix off the filename
    $filename =~ s/\.pm$//;

    $this->{name} = $filename;

    return $this;

}


###############################################################################
#
# do - executing the test - overridden by subclasses
#
###############################################################################

sub do {

    my ($this, $expression) = @_;

    Goo::Prompter::say("No tests to run");

}


###############################################################################
#
# show - the result of a test
#
###############################################################################

sub show {

    my ($this, $test_expression, $description) = @_;

    Goo::Prompter::say("Test output is: <$test_expression>");

}


###############################################################################
#
# ok - is the expression defined?
#
###############################################################################

sub ok {

    my ($this, $test_expression, $description) = @_;

    # print $test_expression."\n";

    if ($test_expression) {
        Goo::Prompter::say("ok - $description");
        $this->{passcount}++;
    } else {
        Goo::Prompter::yell("[" . caller() . "] not ok - $description");
        $this->{failcount}++;
    }

}


###############################################################################
#
# not_ok - the reverse of ok
#
###############################################################################

sub not_ok {

    my ($this, $test_expression, $description) = @_;

    # print $test_expression."\n";
    $this->ok(!$test_expression, $description);

}


###############################################################################
#
# is_array - is the expression defined?
#
###############################################################################

sub is_array {

    #my ($this, $thing, $description) = @_;
    #
    #return ref(

}


###############################################################################
#
# show_results - show the results of a test
#
###############################################################################

sub show_results {

    my ($this) = @_;

    Goo::Prompter::say($this->get_results());

}


###############################################################################
#
# get_results - show the results of the tests
#
###############################################################################

sub get_results {

    my ($this) = @_;

    my $passed = $this->{passcount} || 0;
    my $failed = $this->{failcount} || 0;
    my $total  = $passed + $failed;

    if ($total == 0) {
        return "No tests run.";
    }

    #my $percentage = Maths::get_percentage($passed, $total);
    #my $result = ($percentage == 100) ? "passed" : "failed";

    return "$this->{name} $result: $passed passed, $failed failed.";
}


###############################################################################
#
# isa - check if a thing is a thing
#
###############################################################################

#sub isa {
#
#   my ($this, $object, $type) = @_;
#
#   return $object->isa($type);
#
#}


1;



__END__

=head1 NAME

Tester - Test things.

=head1 SYNOPSIS

use Tester;

=head1 DESCRIPTION



=head1 METHODS

=over

=item new

construct a goo object

=item do

executing the test - overridden by subclasses

=item show

the result of a test

=item ok

is the expression defined?

=item not_ok

the reverse of ok

=item is_array

is the expression defined?

=item show_results

show the results of a test

=item get_results

show the results of the tests

=item isa

check if a thing is a thing


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

