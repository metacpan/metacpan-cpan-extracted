#!/usr/bin/perl
package Getopt::toHash;
require Switch;

use strict;
use warnings;
use Switch;

our $VERSION = '1.01';

# ABSTRACT: Turns command line arguments into hash and validates.


=pod
How to use:

use Getopt::toHash;

--Grab all arguments, return into hash ref.
my $Args = Getopt::toHash->get_em();

Everything else is optional beyond this point.

--Validation
If you want the module to only make sure certain arguments are there and not validate them.
$Args->validate('required'=>['-a','-b','-c']);

The Module can validate on 7 Different constraints
REGEXP		- {'REGEXP=>'^[-+]?[0-9]'}       - Specify a regex the passed data must comply with.
MINMAX		- {'MINMAX'=>{min=>20,max=>40}}  - Specify minimum and maximum numbers the argument must be.
GREATER_THAN	- {'GREATER_THAN'=>{min=>20}}    - Specify a minimum number the argument must be.
LESS_THAN	- {'LESS_THAN'=>{max=>40}}	 - Specify a maximum number the argument must be lower than.
ASCII		- ['ASCII']    - The argument must be any ASCII text with spaces allowed.
NOSPACES	- ['NOSPACES'] - The argument must have no spaces.
ANY		- ['ANY']      - The argument must be defined.

You can validate each argument on as many types of validation as you want by stringing together each array ref or hash. The Argument must pass each constraint

--Example 1 - Validating with a inline object.
$Args->validate( '-a'=>[ 'ASCII','NOSPACES',{ 'MINMAX'=>{min=>20,max=>40} } ] );

--Example 2 - Validating with a hash spec.
my %spec = ( '-a'=>[ 'ASCII','NOSPACES', {'MINMAX'=>{min=>20,max=>40} } ] );
$Args->validate(%spec);

The module will display error messages and die on failed validation by default. If you dont want this you can pass...
$Args->validate( no_errors=>'1','-a'=>[ 'ASCII','NOSPACES',{ 'MINMAX'=>{min=>20,max=>40} } ] );
=cut


sub get_em {

	my $class = shift;
	my @args = @ARGV;
	my $arg_count = scalar @ARGV;

	if (!@ARGV) {return;}

	my $arg_hash;

	# Make sure there is even number of args and values passed
	if (($arg_count % 2) != 0) { die "Odd number of arguments ($arg_count) passed, pass in (-arg value) pairs"; }

	my $it = natatime( 2, @args );
	while (my @vals = $it->()) {
		$arg_hash = put_em_in($arg_hash, @vals);
	}

	bless $arg_hash, $class;

	return $arg_hash;

}

sub put_em_in {

	my $self = shift;
	my @pair = @_;

	my $arg = $pair[0];
	my $val = $pair[1];

	chomp($val);
	chomp($arg);

	if ($arg !~ /-/) { die "Specify arguments with a \"-\"";}

	if (exists $self->{$arg}) {
		die "Lets not pass the same argument twice, ok?";
	}

	$self->{$arg} = $val;

	return $self;

}

#from List::Utils
sub natatime ($@) {

    my $n = shift;
    my @list = @_;

    return sub
    {
        return splice @list, 0, $n;
    }
}

sub validate {

	my $hash = shift;
	my %passed = @_;
	my $errors = 'yes';

	my $self;

	#Foreach of the passed Args set a hash key in $self
  foreach my $key (keys %passed) {
      if (defined($passed{$key})) {
          $self->{$key} = $passed{$key};
      }
  }

	if (exists $self->{no_errors}) {
		$errors = 'no';
		delete $self->{no_errors};
	}

  #If you only pass required args
	if (exists $self->{required}) {
		foreach my $arg (@{$self->{required}}) {
			if (!exists $hash->{$arg}){
				die "You must pass $arg\n";
			} else {
				$hash->{valid} = 'TRUE';
			}
		}

		return $hash;

	} else {

		my $rv;
		foreach my $key (keys %{$self}) {

			foreach my $entry (@{$self->{$key}}) {

				my $ref_type = ref($entry);

				if ($ref_type ne 'HASH' and $ref_type) { die "Invalid validation structure - $ref_type - for $key.\n"; }

				if ($ref_type eq 'HASH') {

					foreach my $key2 (keys %{$entry}) {

						switch ($key2) {
							case /REGEXP/    			 { $rv->{$key}->{$key2} = REGEXP($hash->{$key},$entry->{$key2}); }
							case /MINMAX/    			 { $rv->{$key}->{$key2} = MINMAX($hash->{$key},$entry->{$key2}->{min},$entry->{$key2}->{max}); }
							case /GREATER_THAN/    { $rv->{$key}->{$key2} = GREATER_THAN($hash->{$key},$entry->{$key2}->{min}); }
							case /LESS_THAN/   	   { $rv->{$key}->{$key2} = LESS_THAN($hash->{$key},$entry->{$key2}->{max}); }
							else									 { warn "$entry is not a validation type.\n"; }
						}
					}
				}

				if (!$ref_type) {

					switch ($entry) {
						case /ASCII/    { $rv->{$key}->{$entry} = ASCII($hash->{$key}); }
						case /NOSPACES/ { $rv->{$key}->{$entry} = NOSPACES($hash->{$key}); }
						case /ANY/      { $rv->{$key}->{$entry} = ANY($hash->{$key}); }
						case /INT/      { $rv->{$key}->{$entry} = INT($hash->{$key}); }
						else						{ warn "$entry is not a validation type.\n"; }
					}
				}
			}
		}
		if ($errors eq 'yes') {
			results($rv);
		}

		$hash->{validation} = $rv;
		return $hash;
	}
}

sub results {
	my $self = shift;
	my $validation_fails;

	foreach my $arg (keys %{$self}) {

		foreach my $type (keys %{$self->{$arg}}) {
			my $result = $self->{$arg}->{$type}->{result};
			my $data = $self->{$arg}->{$type}->{data};

			if ($result eq 'INVALID') {
				$validation_fails++;
				print "Invalid [$arg], Type [$type]";
				while (my($k,$v) = each %{$self->{$arg}->{$type}} ) {
					if ($k eq 'data' or $k eq 'result'){next;}
					print ", Req: ($k = $v)";
				}
				print ", Data: $data.\n";
			}
		}
	}
	if ($validation_fails) {
		die "$validation_fails Invalid arguments.\n";
	}
}

sub ASCII {
    my $data = shift;

		if (!defined $data) {	return {result=>'INVALID',data=>'NOT_DEFINED'};	}
    if ($data =~ /^[\x20-\x7E]+$/) { return {result=>'VALID',data=>$data}; }

		return {result=>'INVALID',data=>$data};
}

sub NOSPACES {
    my $data = shift;

		if (!defined $data) {	return {result=>'INVALID',data=>'NOT_DEFINED'};	}
    if ($data !~ /\s/) { return {result=>'VALID',data=>$data}; }

		return {result=>'INVALID',data=>$data};
}

sub ANY {
   	my $data = shift;

		if (!defined $data) {	return {result=>'INVALID',data=>'NOT_DEFINED'};	}
    if (defined $data) { return {result=>'VALID',data=>$data}; }

		return {result=>'INVALID',data=>$data};
}

sub INT {
	my $data = shift;

	if (!defined $data) {	return {result=>'INVALID',data=>'NOT_DEFINED'};	}
	if ($data !~ qr/^[0-9]*$/) {	return {result=>'INVALID',data=>$data};	}

	return {result=>'VALID',data=>$data};
}

sub REGEXP {
    my $data = shift;
    my $regexp = shift;

		if (!defined $data) {	return {result=>'INVALID',data=>'NOT_DEFINED'};	}
		if (!$regexp) {	die "{'REGEXP=>'^[-+]?[0-9]'} Bad structure for REGEXP validation\n";	}
    if ($data !~ /$regexp/) { return {result=>'INVALID',data=>$data}; }

		return {result=>'VALID',data=>$data};
}


sub MINMAX {
	my $data = shift;
  my $min = shift;
  my $max = shift;

	if (!defined $data) {	return {result=>'INVALID',data=>'NOT_DEFINED'};	}
	if (!$min or !$max) {	die "{'MINMAX'=>{min=>20,max=>40}} Bad structure for MINMAX validation\n";}
	if ($min !~ qr/^[0-9]*$/ or $max !~ qr/^[0-9]*$/) {	die "Numeric only for min and max on MINMAX validation\n";}
	if ($data !~ qr/^[0-9]*$/) { return {result=>'INVALID',data=>$data,min=>$min,max=>$max};	}
  if ($data <= $min or $data >= $max ) {	return {result=>'INVALID',data=>$data,min=>$min,max=>$max}; }

  return {result=>'VALID',data=>$data,min=>$min,max=>$max};
}

sub GREATER_THAN {
    my $data = shift;
	  my $min = shift;

		if (!defined $data) {	return {result=>'INVALID',data=>'NOT_DEFINED'};	}
		if (!$min) { die "{'GREATER_THAN'=>{min=>20}} Bad structure for GREATER_THAN validation\n";	}
		if ($min !~ qr/^[0-9]*$/) {	die "Numeric only for min on GREATER_THAN validation\n";	}
		if ($data !~ qr/^[0-9]*$/) { return {result=>'INVALID',data=>$data,min=>$min};}
    if ($data <= $min ) {	return {result=>'INVALID',data=>$data,min=>$min}; }

    return {result=>'VALID',data=>$data,min=>$min};
}

sub LESS_THAN {
	my $data = shift;
	my $max = shift;

	if (!defined $data) {	return {result=>'INVALID',data=>'NOT_DEFINED'};	}
	if ($max !~ qr/^[0-9]*$/) {	die "{'LESS_THAN'=>{max=>40}} - Bad structure for LESS_THAN validation\n";	}
	if ($data !~ qr/^[0-9]*$/) {	return {result=>'INVALID',data=>$data,max=>$max};	}
	if ($data >= $max ) {	return {result=>'INVALID',data=>$data,max=>$max};	}

	return {result=>'VALID',data=>$data,max=>$max};
}

1;
