#-----------------------------------------------------------------
# MOBY::Client::MobyUnitTest
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: MobyUnitTest.pm,v 1.5 2009/02/03 21:56:19 kawas Exp $
#-----------------------------------------------------------------

package MOBY::Client::MobyUnitTest;

use strict;
use Carp;
use XML::SemanticCompare;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

use vars qw($AUTOLOAD);

#-----------------------------------------------------------------
# load all modules needed
#-----------------------------------------------------------------
use XML::LibXML;
use Data::Dumper;

=head1 NAME

MOBY::Client::MobyUnitTest - Create Unit Tests and test your service

=head1 SYNOPSIS

	use MOBY::Client::MobyUnitTest;
	my $x = MOBY::Client::MobyUnitTest->new;

	# set expected output
	$x->expected_output($control_xml);
	# test expected output with XML output
	my $success = $x->test_output_xml($test_file);
	print "XML matches!\n" if $success;

	# set xpath statement
	$x->xpath($some_xpath);
	# test xpath statement
	$success = $x->test_xpath($test_xml);
	print "xpath success!\n" if $success;

	# set regex statement
	$x->regex($some_regex);
	# test regex statement
	$success = $x->test_regex($test_xml); 
	print "regex success!\n" if $success;

	# get XML differences if any
	my $differences = $x->get_xml_differences($test_xml);

=head1 DESCRIPTION

This module is used for providing unit test case information for any particular service, as well as actually performing the tests on the service.

=cut

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------
# AUTOLOAD
#-----------------------------------------------------------------
sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self)
	  or croak("$self is not an object");

	my $name = $AUTOLOAD;
	$name =~ s/.*://;    # strip fully-qualified portion
	unless ( exists $self->{_permitted}->{$name} ) {
		croak("Can't access '$name' field in class $type");
	}

	my $is_func = $self->{_permitted}->{$name}[1] =~ m/subroutine/i;

	unless ($is_func) {
		if (@_) {
			my $val = shift;
			$val = $val || "";
			return $self->{$name} = $val
			  if $self->{_permitted}->{$name}[1] =~ m/write/i;
			croak("Can't write to '$name' field in class $type");
		} else {
			return $self->{$name}
			  if $self->{_permitted}->{$name}[1] =~ m/read/i;
			croak("Can't read '$name' field in class $type");
		}
	}

	# call a function
	if ($is_func) {
		if (@_) {

			# parameterized call
			my $x = $self->{_permitted}->{$name}[0];
			return $self->$x(shift);
		} else {

			# un-parameterized call
			my $x = $self->{_permitted}->{$name}[0];
			return $self->$x();
		}
	}
}

#-----------------------------------------------------------------
# new
#-----------------------------------------------------------------
sub new {
	my ( $class, %options ) = @_;

	# permitted fields
	my %fields = (

		# attribute	        => [default, accessibility],
		example_input       => [ "",                      'read/write' ],
		expected_output     => [ "",                      'read/write' ],
		regex               => [ "",                      'read/write' ],
		xpath               => [ "",                      'read/write' ],
		test_output_xml     => [ "_test_xml",             'subroutine' ],
		get_xml_differences => [ "_get_xml_differences",  'subroutine' ],
		test_regex          => [ "_test_regex_statement", 'subroutine' ],
		test_xpath          => [ "_test_xpath_statement", 'subroutine' ],
	);

	# create an object
	my $self = { _permitted => \%fields };

	# set user values if they exist
	$self->{example_input}   = $options{example_input}   || '';
	$self->{expected_output} = $options{expected_output} || '';
	$self->{regex}           = $options{regex}           || '';
	$self->{xpath}           = $options{xpath}           || '';

	bless $self, $class;
	return $self;
}

#-----------------------------------------------------------------
# _test_xml: semantically compare $xml to $self->expected_output
#-----------------------------------------------------------------
sub _test_xml {
	my ( $self, $xml ) = @_;
	return undef if $self->expected_output =~ m//g;
	# compare the docs
	my $sc = XML::SemanticCompare->new();
	return $sc->compare($self->expected_output, $xml);
}

#-----------------------------------------------------------------
# _test_xpath_statement: apply xpath to $xml
#-----------------------------------------------------------------
sub _test_xpath_statement {
	my ( $self, $xml ) = @_;
	# no xpath expression, nothing to test
	return undef if $self->xpath =~ m//g;
	# empty xml, nothing to test
	return undef if $xml =~ m//g;
	#instantiate a parser
	my $sc = XML::SemanticCompare->new();
	return $sc->test_xpath($self->xpath, $xml);
}

#-----------------------------------------------------------------
# _test_regex_statement: apply regex to $xml
#-----------------------------------------------------------------
sub _test_regex_statement {
	my ( $self, $xml ) = @_;
	my $regex = $self->regex;
	return undef unless $xml =~ m/$regex/g;
	return 1;
}

#-----------------------------------------------------------------
# _get_xml_differences: 
#    get the differences between $xml and expected xml 
#      and return them
#-----------------------------------------------------------------
sub _get_xml_differences {
	my ( $self, $xml ) = @_;
	croak "not yet implemented ...\n";
}

sub DESTROY { }

1;

__END__


=head1 SUBROUTINES

=head2 new

constructs a new MobyUnitTest reference.
parameters (all optional) include:

=over

=item   C<example_input> - example input to pass to our service when testing it

=item   C<expected_output> - service output xml that is expected given the example input

=item   C<regex> - the regular expression to match against

=item   C<xpath> - the xpath statement to match against

=back

=cut

=head2 example_input 

getter/setter - use to get/set the example input for the service that we are testing.

=cut

=head2 expected_output 

getter/setter - use to get/set the expected output for the service that we are testing given C<example_input>.

=cut

=head2 regex 

getter/setter - use to get/set the regular expression that will be applied agaisnt the actual output for the service that we are testing.

=cut

=head2 xpath 

getter/setter - use to get/set the xpath expression that will be applied against the actual output for the service that we are testing.

=cut

=head2 test_output_xml 

subroutine that determines whether or not the passed in output XML is semantically similar to C<expected_output>.

parameters - a scalar string of XML (or a file location) to test C<expected_output> against.

a true value is returned if both XML docs are semantically similar, otherwise undef is returned. 

=cut

=head2 test_regex

subroutine that applies C<regex> to the passed in output XML.

parameters - a scalar string of XML to test against.

a true value is returned if the regular expression matches, otherwise undef is returned.

=cut

=head2 test_xpath 

subroutine that applies C<xpath> to the passed in output XML.

parameters - a scalar string of XML (or a file location) to test against.

a true value is returned if the xpath statement matches 1 or more nodes in the XML, otherwise undef is returned.

=cut

=head2 get_xml_differences

subroutine that retrieves any differences found when comparing C<expected_output> XML and the XML passed in to this sub.

parameters - a scalar string of XML to test C<expected_output> against.

an array ref of strings representing the differences found between xml docs is returned.

=cut

=cut
