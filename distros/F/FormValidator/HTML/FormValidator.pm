#
#    FormValidator.pm - Object that validates form input data.
#
#    This file is part of FormValidator.
#
#    Author: Francis J. Lacoste <francis.lacoste@Contre.COM>
#
#    Copyright (C) 1999,2000 iNsu Innovations Inc.
#    Copyright (C) 2001 Francis J. Lacoste
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.
#
package HTML::FormValidator;

use HTML::FormValidator::Results;

use strict;

use vars qw( $VERSION );

BEGIN {
    $VERSION = '0.11';
}

=pod

=head1 NAME

HTML::FormValidator - Validates user input (usually from an HTML form) based
on input profile.

=head1 SYNOPSIS

In an HTML::Empberl page:

    use HTML::FormValidator;

    my $validator = new HTML::FormValidator( "/home/user/input_profiles.pl" );
    my ( $valid, $missing, $invalid, $unknown ) = $validator->validate(  \%fdat, "customer_infos" );

=head1 DESCRIPTION

HTML::FormValidator's main aim is to make the tedious coding of input
validation expressible in a simple format and to let the programmer focus
on more interesting task.

When you are coding web application one of the most tedious though
crucial task is to validate user's input (usually submitted by way of
an HTML form). You have to check that each required fields is present
and that some feed have valid data. (Does the phone input looks like a
phone number ? Is that a plausible email address ? Is the YY state
valid ? etc.) For simple form, this is not really a problem but as
forms get more complex and you code more of them this task became
really boring and tedious.

HTML::FormValidator lets you defines profiles which defines the
required fields and their format. When you are ready to validate the
user's input, you tell HTML::FormValidator the profile to apply to the
user data and you get the valid fields, the name of the fields which
are missing, the name of the fields that contains invalid input and
the name of the fields that are unknown to this profile.

You are then free to use this information to build a nice display to
the user telling which fields that he forgot to fill.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $profile_file	= shift;
    my $profiles	= undef;

    if ( ref $profile_file ) {
	# Profile already passed as an hash reference.
	$profiles	= $profile_file;
	$profile_file	= undef;
    }


    bless { profile_file => $profile_file,
	    profiles	 => $profiles,
	  }, $class;
}

=pod

=head1 INPUT PROFILE SPECIFICATION

To create a HTML::FormValidator, use the following :

    my $validator = new HTML::FormValidator( $input_profile );

Where $input_profile may either be an hash reference to an input
profiles specification or a file that will be evaluated at runtime to
get a hash reference to an input profiles specification.

The input profiles specification is an hash reference where each key
is the name of the input profile and each value is another hash
reference which contains the actual profile elements. If the input
profile is specified as a file name, the profiles will be reread each
time that the disk copy is modified.

Here is an example of a valid input profiles specification :

    {
	customer_infos => {
	    optional     =>
		[ qw( company fax country ) ],
	    required     =>
		[ qw( fullname phone email address city state zipcode ) ],
	    constraints  =>
		{
		    email	=> "email",
		    fax		=> "american_phone",
		    phone	=> "american_phone",
		    zipcode	=> '/^\s*\d{5}(?:[-]\d{4})?\s*$/',
		    state	=> "state",
		},
	    defaults => {
		country => "USA",
	    },
	},
	customer_billing_infos => {
	     optional	    => [ "cc_no" ],
	     dependencies   => {
		"cc_no" => [ qw( cc_type cc_exp ) ],
	     },
	     constraints => {
		cc_no      => {  constraint  => "cc_number",
				 params	     => [ qw( cc_no cc_type ) ],
				},
		cc_type	=> "cc_type",
		cc_exp	=> "cc_exp",
	      }
	    filters       => [ "trim" ],
	    field_filters => { cc_no => "digit" },
	},
    }

The following are the valid fields for an input specification :

=over

=item required

This is an array reference which contains the name of the fields which
are required. Any fields in this list which are not present in the
user input will be reported as missing.

=item optional

This is an array reference which contains the name of optional fields.
These are fields which MAY be present and if they are, they will be
check for valid input. Any fields not in optional or required list
will be reported as unknown.

=item dependencies

This is an hash reference which contains dependencies information.
This is for the case where one optional fields has other requirements.
For example, if you enter your credit card number, the field cc_exp
and cc_type should also be present. Any fields in the dependencies
list that is missing when the target is present will be reported as
missing.

=item conflicts

This is an hash reference which contains conflicts information. The
key is the name of the field, which if present, the fields in the
array reference value shouldn't be present. The fields which conflicts 
with another will be reported as conflicting.

=item defaults

This is an hash reference which contains defaults which should be
substituted if the user hasn't filled the fields. Key is field name
and value is default value which will be returned in the list of valid
fields.

=item filters

This is a reference to an array of filters that will be applied to ALL
optional or required fields. This can be the name of a builting filter
(trim,digit,etc) or an anonymous subroutine which should take one parameter, the field value and return the (possibly) modified value.

=item field_filters

This is a reference to an hash which contains reference to array of
filters which will be apply to specific input fields. The key of the
hash is the name of the input field and the valud is a reference to an
array of filters like for the filters parameter.

=item constraints

This is a reference to an hash which contains the constraints that
will be used to check wheter or not the field contains valid data.
Constraint can be either the name of a builtin constraint function
(see below), a perl regexp or an anonymous subroutine which will check
the input and return 1 or 0 depending on the input's validity.
The constraint function may also -1 to express data that is valid but 
not recommended.

The constraint function takes one parameter, the input to be validated
and returns 1, 0 or -1. It is possible to specify the parameters
that will be passed to the subroutine. For that use an hash reference
which contains in the I<constraint> element, the anonymous subroutine
or the name of the builtin and in the I<params> element the name of
the fields to pass a parameter to the function. (Don't forget to
include the name of the field to check in that list!) For an example,
look at the I<cc_no> constraint example.

=back

=cut

sub load_profiles {
    my $self = shift;

    my $file = $self->{profile_file};
    return unless $file;

    die "No such file: $file\n" unless -f $file;
    die "Can't read $file\n"	unless -r _;

    my $mtime = (stat _)[9];
    return if $self->{profiles} and $self->{profiles_mtime} <= $mtime;

    $self->{profiles} = do $file;
    die "Error in input profiles: $@\n" if $@;
    die "Input profiles didn't return an hash ref\n"
      unless ref $self->{profiles} eq "HASH";

    $self->{profiles_mtime} = $mtime;
}

=pod

=head1 VALIDATING INPUT

    my $results = $validator->check( \%fdat, "customer_infos" );

    my %fdat = $results->valid();
    if ( $results->has_missing) ) {
	foreach my $f ( $results->missing ) {
	    print "Field ", $f , " is missing\n";
	}
    }

To validate input you use the check() method. This method takes two
parameters :

=over

=item data

Contains an hash which should correspond to the form input as
submitted by the user. This hash is not modified by the call to validate.

=item profile

Can be either a name which will be used to lookup the corresponding profile
in the input profiles specification, or it can be an hash reference to the
input profile which should be used.

=back

This method returns an HTML::FormValidator::Results(3) object. This
object can then be queried for valid, invalid, unknown, missing fields
or fields which cause conflicts or have warnings. Consult the
HTML::FormValidator::Results(3) for more information.

There is also a deprecated method which takes the same parameter but
returns its as result in a 4 elements array.

=over

=item valid

This is an hash reference to the valid fields which were submitted in
the data. The data may have been modified by the various filters specified.

=item missing

This is a reference to an array which contains the name of the missing
fields. Those are the fields that the user forget to fill or filled
with space. These fields may comes from the I<required> list or the
I<dependencies> list.

=item invalid

This is a reference to an hash which contains the the fields and their value
which failed their constraint check.

=item unknown

This is a reference to an hash which contains the fields which are unknown
to the profile. Whether or not this indicates an error in the user
input is application dependant.

=back

=cut

sub validate {
    my $data_set = check( @_ );

    my $valid	= $data_set->valid();
    my $missing	= $data_set->missing();
    my $invalid	= [ $data_set->invalid ];
    my $unknown = [ $data_set->unknown ];

    return ( $valid, $missing, $invalid, $unknown );
}

sub check {
    my ( $self, $data, $name ) = @_;

    my $profile;
    if ( ref $name ) {
	$profile = $name;
    } else {
	$self->load_profiles;
	$profile = $self->{profiles}{$name};
	die "No such profile $name\n" unless $profile;
    }
    die "Invalid input profile\n" unless ref $profile eq "HASH";

    new HTML::FormValidator::Results( $profile, $data );
}

1;

__END__

=pod

=head1 SEE ALSO

HTML::FormValidator::Constraints(3) HTML::FormValidator::Filters(3)
HTML::FormValidator::ConstraintsFactory(3) HTML::FormValidator::Results(3)

=head1 AUTHOR

Francis J. Lacoste <francis.lacoste@Contre.COM>

=head1 COPYRIGHT

Copyright (c) 1999,2000 iNsu Innovations Inc.
Copyright (c) 2001 Francis J. Lacoste
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=cut

