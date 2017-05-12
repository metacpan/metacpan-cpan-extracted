package Geo::Address::Mail::Standardizer::USPS::AMS::Results;

use Moose;
use Message::Stack;
use Message::Stack::Message;
use MooseX::Storage;
with qw(MooseX::Storage::Deferred);

=head1 NAME

Geo::Address::Mail::Standardizer::USPS::AMS::Results - results object from the USPS Address Matching System

=head1 SYNOPSIS

 my $address = new Geo::Address::Mail::US;
 my $ms      = new Geo::Address::Mail::Standardizer::USPS::AMS;
 my $result  = $ms->standardize($addr);

 $result->address;    # new standardized Geo::Address::Mail::US object
 $result->multiple;   # boolean indicating whether multiple addresses are returned.
 $result->single;     # boolean indicating whether a single address was returned.
 $result->found;      # integer indicating the number of candidates
 $result->error;      # string with an error message
 $result->default;    # boolean indicating a Z4_DEFAULT return code, which means:
                      #  "An address was found, but a more specific address could be
                      #  found with more information"
 $result->candidates; # reference to an array of Geo::Address::Mail::US objects, all
                      #  of which are possible matches
 $result->changed;    # A hashref whose values are key => 1 pairs indicating which
                      #  fields were changed during standardization

 $result->standardized_address; # The standardized address, in the case of a single
                                # matching address

=head1 DESCRIPTION

The results of a call to Geo::Address::Mail::Standardizer::USPS::AMS's standardize method.

=cut

extends 'Geo::Address::Mail::Standardizer::Results';

use Geo::Address::Mail::US;
use Moose::Util::TypeConstraints;

our $VERSION = '0.05';

subtype 'Address'		=> as 'Geo::Address::Mail::US';
subtype 'AddressList'	=> as 'ArrayRef[Address]';

coerce 'Address'
	=> from 'HashRef'
	=> via { new Geo::Address::Mail::US $_ };

coerce 'AddressList'
	=> from 'ArrayRef[HashRef]'
	=> via { [ map { new Geo::Address::Mail::US $_ } @$_ ] };

has error		=> (is => 'ro', isa => 'Str|Undef', predicate => 'has_error');
has found		=> (is => 'ro', isa => 'Int', predicate => 'has_found');
has default		=> (is => 'ro', isa => 'Bool', predicate => 'has_default');
has single		=> (is => 'ro', isa => 'Bool', predicate => 'has_single');
has multiple	=> (is => 'ro', isa => 'Bool', predicate => 'has_multiple');
has changed		=> (is => 'ro', isa => 'HashRef', predicate => 'has_changed');
has footnotes	=> (is => 'ro', isa => 'HashRef', predicate => 'has_footnotes');
has messages	=> ( is => 'ro', isa => 'Message::Stack', lazy_build => 1);

has candidates =>
	is		=> 'ro',
	isa		=> 'AddressList',
	coerce	=> 1,
	traits	=> [ 'Array' ],
	handles	=>
	{
		has_candidates	=> 'count',
		num_candidates	=> 'count',
		get_candidate	=> 'get',
	};

has '+standardized_address' =>
	isa		=> 'Address',
	coerce	=> 1;


sub _build_messages {
    my $self = shift;

    # These are the footnotes direct from the USPS AMS API docs
    my $codes = {

		# The address was found to have a different 5-digit ZIP Code than given in the
		# submitted list. The correct ZIP Code is shown in the output address.
        'A' => Message::Stack::Message->new(
			id => 'zip_code_corrected',
			level => 'info',
			scope => 'standardization',
			subject => 'zip',
			text => 'ZIP Code Corrected',
		),

		# The spelling of the city name and/or state abbreviation in the submitted address
		# was found to be different than the standard spelling. The standard spelling of the
		# city name and state abbreviation are shown in the output address.
        'B' => Message::Stack::Message->new(
			id => 'city_state_corrected',
			level => 'info',
			scope => 'standardization',
			subject => 'address',
			text => 'City/State Corrected',
		),

		# The ZIP Code in the submitted address could not be found because neither a
		# valid city, state, nor valid 5-digit ZIP Code was present. It is also recommended
		# that the requestor check the submitted address for accuracy.
        'C' => Message::Stack::Message->new(
			id => 'invalid_city_state_zip',
			level => 'error',
			scope => 'standardization',
			subject => 'zip',
			text => 'Invalid City/State/ZIP',
		),

		# This is a record listed by the United States Postal Service on the national
		# ZIP+4 file as a non-deliverable location. It is recommended that the requestor
		# verify the accuracy of the submitted address.
        'D' => Message::Stack::Message->new(
			id => 'no_zip_code_assigned',
			level => 'error',
			scope => 'standardization',
			subject => 'zip',
			text => 'No ZIP+4 Code Assigned',
		),

		# Multiple records were returned, but each shares the same 5-digit ZIP Code.
        'E' => Message::Stack::Message->new(
			id => 'multiple_within_zip',
			level => 'notice',
			scope => 'standardization',
			subject => 'zip',
			text => 'ZIP Code Assigned with a Multiple Response',
		),

		# The address, exactly as submitted, could not be found in the city, state, or
		# ZIP Code provided. It is also recommended that the requestor check the submitted
		# address for accuracy. For example, the street address line may be abbreviated
		# excessively and may not be fully recognizable.
        'F' => Message::Stack::Message->new(
			id => 'address_not_found',
			level => 'error',
			scope => 'standardization',
			subject => 'address',
			text => 'Address Not Found',
		),

		# Information in the firm line was determined to be a part of the address. It
		# was moved out of the firm line and incorporated into the address line.
        'G' => Message::Stack::Message->new(
			id => 'firm_line_incorporated',
			level => 'notice',
			scope => 'standardization',
			subject => 'address',
			text => 'All or Part of the Firm Line User For Address Line',
		),

		# ZIP+4 information indicates this address is a building. The address as
		# submitted does not contain an apartment/suite number. It is recommended
		# that the requestor check the submitted address and add the missing apartment
		# or suite number to ensure the correct Delivery Point Barcode (DPBC).
        'H' => Message::Stack::Message->new(
			id => 'missing_secondary_number',
			level => 'warning',
			scope => 'standardization',
			subject => 'address',
			text => 'Missing Secondary Number',
		),

		# More than one ZIP+4 Code was found to satisfy the address as submitted.
		# The submitted address did not contain sufficiently complete or correct
		# data to determine a single ZIP+4 Code. It is recommended that the requestor
		# check the address for accuracy and completeness. For example, firm name,
		# or institution name, doctor’s name, suite number, apartment number, box
		# number, floor number, etc. may be missing or incorrect. Also pre-directional
		# or post-directional indicators (North = N, South = S, East = E, West = W,
		# etc.) and/or street suffixes (Street = ST, Avenue = AVE, Road = RD,
		# Circle = CIR, etc.) may be missing or incorrect.
        'I' => Message::Stack::Message->new(
			id => 'insufficient_data',
			level => 'error',
			scope => 'standardization',
			subject => 'address',
			text => 'Insufficient/Incorrect Data',
		),

		# The input contained two addresses. For example: 123 MAIN ST PO BOX 99.
        'J' => Message::Stack::Message->new(
			id => 'dual_address',
			level => 'error',
			scope => 'standardization',
			subject => 'address',
			text => 'PO Box Dual Address',
		),

		# CASS rule does not allow a match when the cardinal point of a directional
		# changes more than 90%.
        'K' => Message::Stack::Message->new(
			id => 'cardinal_rule_violation',
			level => 'error',
			scope => 'standardization',
			subject => 'address',
			text => 'Multiple Response Due To Cardinal Rule',
		),

		# An address component (i.e., directional or suffix only) was added, changed,
		# or deleted in order to achieve a match.
        'L' => Message::Stack::Message->new(
			id => 'address_component_changed',
			level => 'info',
			scope => 'standardization',
			subject => 'address',
			text => 'Address Component Changed',
		),

		# The spelling of the street name was changed in order to achieve a match.
        'M' => Message::Stack::Message->new(
			id => 'street_name_changed',
			level => 'info',
			scope => 'standardization',
			subject => 'address',
			text => 'Street Name Changed',
		),

		# The delivery address was standardized. For example, if STREET was in the
		# delivery address, the system will return ST as its standard spelling.
        'N' => Message::Stack::Message->new(
			id => 'address_standardized',
			level => 'info',
			scope => 'standardization',
			subject => 'address',
			text => 'Address Standardized',
		),

		# More than one ZIP+4 Code was found to satisfy the address as submitted. The
		# lowest ZIP +4 addon may be used to break the tie between the records.
        'O' => Message::Stack::Message->new(
			id => 'lowest_four_tiebreaker',
			level => 'notice',
			scope => 'standardization',
			subject => 'zip',
			text => 'Multiple response can be broken by using the lowest +4',
		),

		# The delivery address is matchable, but is known by another (preferred) name.
		# For example, in New York, NY, AVENUE OF THE AMERICAS is also known as 6TH AVE.
		# An inquiry using a delivery address of 55 AVE OF THE AMERICAS would be flagged
		# with a Footnote Flag P.
        'P' => Message::Stack::Message->new(
			id => 'better_address_exists',
			level => 'notice',
			scope => 'standardization',
			subject => 'address',
			text => 'Better Address Exists',
		),

		# Match to an address with a unique ZIP Code.
        'Q' => Message::Stack::Message->new(
			id => 'unique_zip_code',
			level => 'info',
			scope => 'standardization',
			subject => 'zip',
			text => 'Unique ZIP Code Match',
		),

		# The delivery address is matchable, but the EWS file indicates that an exact
		# match will be available soon.
        'R' => Message::Stack::Message->new(
			id => 'ews_no_match',
			level => 'error',
			scope => 'standardization',
			subject => 'ews',
			text => 'No Match due to EWS',
		),

		# The secondary information (i.e., floor, suite, apartment, or box number) does
		# not match that on the national ZIP+4 file. This secondary information, although
		# present on the input address, was not valid in the range found on the national
		# ZIP+4 file.
        'S' => Message::Stack::Message->new(
			id => 'incorrect_secondary_number',
			level => 'error',
			scope => 'standardization',
			subject => 'secondary_number',
			text => 'Incorrect Secondary Number',
		),

		# The search resulted in a single response; however, the record matched was
		# flagged as having magnet street syndrome. “Whenever an input address has a
		# single suffix word or a single directional word as the street name, or whenever
		# the ZIP+4 File records being matched to have a single suffix word or a single
		# directional word as the street name field, then an exact match between the
		# street, suffix and/or post- directional and the same components on the ZIP+4
		# File must occur before a match can be made. Adding, changing or deleting a
		# component from the input address to obtain a match to a ZIP+4 record will be
		# considered incorrect.” Instead of returning a “no match” in this situation a
		# multiple response is returned to allow access the candidate record.
        'T' => Message::Stack::Message->new(
			id => 'magnet_street_syndrome',
			level => 'warning',
			scope => 'standardization',
			subject => 'address',
			text => 'Multiple response due to Magnet Street Syndrome',
		),

		# The city or post office name in the submitted address is not recognized
		# by the United States Postal Service as an official last line name (preferred
		# city name), and is not acceptable as an alternate name. This does denote an
		# error and the preferred city name will be provided as output.
        'U' => Message::Stack::Message->new(
			id => 'unofficial_post_office_name',
			level => 'warning',
			scope => 'standardization',
			subject => 'post_office',
			text => 'Unofficial Post Office Name',
		),

		# The city and state in the submitted address could not be verified as
		# corresponding to the given 5-digit ZIP Code. This comment does not
		# necessarily denote an error; however, it is recommended that the requestor
		# check the city and state in the submitted address for accuracy.
        'V' => Message::Stack::Message->new(
			id => 'unverifiable_city_state',
			level => 'warning',
			scope => 'standardization',
			subject => 'city_state',
			text => 'Unverifiable City/State',
		),

		# The input address record contains a delivery address other than a PO BOX,
		# General Delivery, or Postmaster with a 5-digit ZIP Code that is identified
		# as a “small town default.” The United States Postal Service does not provide
		# street delivery for this ZIP Code. The United States Postal Service requires
		# use of a PO BOX, General Delivery, or Postmaster for delivery within this ZIP
		# Code.
        'W' => Message::Stack::Message->new(
			id => 'invalid_delivery_address',
			level => 'error',
			scope => 'standardization',
			subject => 'address',
			text => 'Invalid Delivery Address',
		),

		# Default match inside a unique ZIP Code.
        'X' => Message::Stack::Message->new(
			id => 'unique_zip_code_default',
			level => 'info',
			scope => 'standardization',
			subject => 'default',
			text => 'Unique Zip Code Default',
		),

		# Match made to a record with a military ZIP Code.
        'Y' => Message::Stack::Message->new(
			id => 'military_match',
			level => 'info',
			scope => 'standardization',
			subject => 'match',
			text => 'Military Match',
		),

		# The ZIPMOVE product shows which ZIP + 4 records have moved from one ZIP Code to
		# another. If an input address matches to a ZIP + 4 record which the ZIPMOVE product
		# indicates as having moved, the search is performed again in the new ZIP Code.
        'Z' => Message::Stack::Message->new(
			id => 'zip_move_match',
			level => 'info',
			scope => 'standardization',
			subject => 'match',
			text => 'ZIP Move Match',
		)
    };

	# All of that, for this.
	my $stack = Message::Stack->new;
	my $footnotes = $self->footnotes;
	foreach my $fn (keys(%{$footnotes})) {
		$stack->add($codes->{uc($fn)});
	}

    return $stack;
}

__PACKAGE__->meta->make_immutable;


=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2010 Mike Eldridge

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


1;
