package HTML::CheckArgs;

=pod

=head1 NAME

HTML::CheckArgs - Validate data passed to web applications

=head1 SYNOPSIS

  use HTML::CheckArgs;

  my @banned_domains = ( 'whitehouse.gov', 'gop.com' );
  my $config = {
    email_address => {
      as        => 'email',
      required  => 1,
      label     => 'Email Address',
      order     => 1,
      params    => { banned_domains => \@banned_domains },
    },
	num_tickets => {
	  as        => 'integer',
	  required  => 1,
	  label     => 'Number of Tickets',
	  order     => 2,
	  params    => { min => 0, max => 10 },
	},
  };

  my $handler = HTML::CheckArgs->new( $config );
  my ( $error_message, $error_code );
  foreach my $field ( sort { $config->{$a}{order} <=> $config->{$b}{order} } keys %$config ) {
    if ( $handler->validate( $field, $ARGS{$field} ) ) {
      $ARGS{$field} = $handler->value;
    } else {
      push( @$error_message, $handler->error_message );
      push( @$error_code, $handler->error_code );
    }
  }

=head1 DESCRIPTION

HTML::CheckArgs validates data passed to web applications. Architecturally,
it is based on CGI::Untaint, and we follow that model of extensibility
as well.

Most of the work is done in the $config hashref. $config's keys are the
fieldnames to be validated. The following parameters can be passed in:

=over

=item B<as:>

Name of the module that should be used to validate the data. The following modules
are available:

=over

=item cc_expiration

Passed a date string in the format YYYYMM, will determine if the string is valid, and
if the date is in the future.

=item cc_number

Validates credit card numbers based on Luhn checksum.

=item country

Validates 2-character country code or full country name per Georgraphy::Countries.

=item date

Passed a date string, a format, and a regex of the format, will determine if the string
represents a valid date.

=item dollar

Validates a dollar figure. Can optionally specify minimum and maximum vaues to check
against.

=item email

Uses Email::Valid to check email addresses. Can optionally specify no administrative
addresses (e.g. root@domain.com), no government addresses (me@dot.gov), or no addresses
from a list of domains passed to the module.

=item integer

Determines if number is a valid interger. Can optionally specify minimum and maximum
values to check against.

=item option

Determines if a value is a member of a list passed to the module. Useful when the form
input is a select or a radio button.

=item phone

Determines if a string is valid phone number. Only does strict validation on US phone numbers,
but other formats could be included.

=item postal_code

Validates a postal  or ZIP code. Only does strict validation on US ZIP codes.

=item state

Validates a two-character state abbrieviation or full name. Only does strict validation
on US values.

=item string

A catch-all class. Can format the string per the routines in HTML::FormatData, and can
also do regex checks, checks on the number of character, number of words, etc.

=item url

Uses URL::Find to validate the URL. Can optionally check the URL via LWP::UserAgent.

=back

=item B<required:>

Set to 1 if the field is required. Default is 0 (not required).

=item B<order:>

The order the fields should be evaluated in.

=item B<label:>

Field name label to be used for user error messages.

=item B<private:>

A flag that can be passed to your error reporting instrument as an 
indicator of whether the error should be displayed to the user. Default
is 0.

=item B<params:>

Extra parameters that should be passed to the specific module
validating the data. Passing parameters to a module that does not support
use this feature will cause it to 'die'. Passing unknown parameters will
also cause it to 'die'.

=item B<noclean:>

Determines if the value returned should be cleaned up if the value is validated.
Set to 1 to preserve the original value. Default is 0 (value will be cleaned).
Some modules do not support cleaning the input. If you pass 'noclean' to one of
these modules, it will 'die'.

=item B<untaint:>

Set to 1 if you want the value to be untainted. Default is 0 (don't untaint).

Please note that all untainting is done after a successful is_valid call to
the specific validation module. If a value is_valid, we assume it is safe to
untaint it without further checks, so the regex pattern /(.*)/s is used. 
If you want more rigorous checking, it is advisable that you improve the
is_valid code or do alternate checks before untainting the value.

=back

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

use Carp qw( croak );
use Scalar::Util qw( tainted );

our $VERSION = '0.11';

=pod

=head2 new( $config [, $alt_messages ] )

This method creates a new HTML::CheckArgs object, using the $config hashref.
Returns the blessed object.

An optional $alt_messages parameter -- a hashref of alternate error messages
keyed error codes -- can be used to override the default error messages passed
back from the modules that perform the actual verification.

=cut

sub new {
	my $class = shift;
	my $config = shift;
	my $alt_messages = shift;

	bless { _config => $config, _alt_messages => $alt_messages }, $class;
}

=pod

=head2 accessors

The following data can be get/set:

=over

=item error_code

Each error registered has a  unique code attached to it, in the format
name_of_module_xx, where xx is a numerical code.

=item error_message

Each error also has a text message suitable for presentation to the
user. Creating a custom lookup list based on error codes is certainly
possible if you wish to override the default values.

=item value

If there is an error, 'value' retains the value originally passed in.
Otherwise, value has the original value or a cleaned-up version 
depending on the $config hashref settings.

=item config

This gets the $config hashref value for a particular key. This is then
passed to the specific module called to validate a specific value.

=item alt_message

This gets the $alt_messages hashref value for a particular key. This is then
used to override the default error message associated with a particular code.

=back

=cut

sub error_code {
	my $self = shift;
	$self->{error_code} = shift if @_;
	return $self->{error_code};
}

sub error_message {
	my $self = shift;
	$self->{error_message} = shift if @_;
	return $self->{error_message};
}

sub value {
	my $self = shift;
	$self->{value} = shift if @_;
	return $self->{value};
}

sub config {
	my $self = shift;
	my $field = shift;
	return $self->{_config}{$field};
}

sub alt_message {
	my $self = shift;
	my $code = shift;
	return $self->{_alt_messages}{$code};
}

=pod

=head2 validate( $field, $value )

Passes $field, $value and field-specific $config info
to the proper module for validation.

Returns true if validation was successful, otherwise false.

=cut

sub validate {
	my $self = shift;
	my $field = shift;
	my $value = shift;

	my $config = $self->config( $field );

	croak( "'as' is a required config parameter" ) unless $config->{as};

	# initialize object vars
	$self->value( undef );
	$self->error_code( undef );
	$self->error_message( undef );

	# trim leading/trailing whitespace from $value
	$value =~ s/^\s+// if $value;
	$value =~ s/\s+$// if $value;

	my $module = 'HTML::CheckArgs::' . $config->{as};
	eval "require $module";
	croak( "Could not instantiate $module: $@" ) if $@;
	my $child = $module->new( $config, $field, $value );

	# validate
	unless ( $child->is_valid ) {
		$self->error_code( $child->error_code );
		if ( my $msg = $self->alt_message( $child->error_code ) ) {
			$self->error_message( $msg );
		} else {
			$self->error_message( $child->error_message );
		}
		return;
	}

	# untaint?
	if ( $config->{untaint} && tainted $child->value ) {
		my $value = $child->value;
		if ( $value =~ m/(.*)/s ) {
			$child->value( $1 );
		} else {
			croak( "Could not untaint $value of type " . $config->{as} );
		}
	}

	$self->value( $child->value );
	return 1;
}

=pod

=head1 AUTHOR

Eric Folley, E<lt>eric@folley.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Eric Folley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
