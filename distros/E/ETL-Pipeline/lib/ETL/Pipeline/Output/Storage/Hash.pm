=pod

=head1 NAME

ETL::Pipeline::Output::Storage::Hash - Holds the current record in a hash

=head1 SYNOPSIS

  with 'ETL::Pipeline::Output::Storage::Hash';

=head1 DESCRIPTION

This role stores the current record in a Perl hash. 
L<ETL::Pipeline::Output/write_record> copies the information out of the hash 
and into permanent storage.

L<ETL::Pipeline/process> wipes out the hash at the start of every input record.
B<ETL::Pipeline::Output::Storage::Hash> creates an entirely new copy. That way
L<ETL::Pipeline::Output/write_record> can safely store the hash reference.

=cut

package ETL::Pipeline::Output::Storage::Hash;
use Moose::Role;

use 5.14.0;
use warnings;

use Carp;
use String::Util qw/hascontent/;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head3 default_fields

This subroutine returns a hash of default fields. L</new_record> initializes
every new record with these values. The consuming class must define the
B<default_fields> method.

B<NOTE:> Do not return a hash reference. Return the hash. B<default_fields> is
called in list context.

=cut

requires 'default_fields';


=head3 current

B<current> is a hash reference of the current record. Fields are added using 
the L</set> method.

=head3 field_names

B<field_names> returns a list of the current field names. It can be used for
traversing the hash.

=head3 get_value

B<get_value> returns the value of a single field. Pass the field name (a.k.a.
the hash key) as the only parameter.

=head3 this_record

B<this_record> returns the complete record as a hash instead of a hash 
reference.

=cut

has 'current' => (
	handles => {
		field_names => 'keys',
		get_value   => 'get', 
		_set_value  => 'set',
		this_record => 'elements', 
	},
	is      => 'rw',
	isa     => 'HashRef[Any]',
	traits  => [qw/Hash/],
);


=head2 Called from L<ETL::Pipeline/process>

=head3 new_record

B<new_record> creates a new hash reference for L</current>. Every record begins
empty. Fields are created through L</set>.

=cut

sub new_record { 
	my $self = shift;

	my %copy = $self->default_fields;
	$self->current( \%copy );
}


=head3 set

B<set> adds a single field to the record. The parameters are a field name 
followed by one or more values. Multiple values are stored as a list reference.

=cut

sub set {
	my ($self, $field, @values) = @_;

	if (hascontent( $field )) {
		$self->_set_value( $field, scalar( @values ) > 1 ? [@values] : $values[0] );
	} else {
		croak 'No field name for "set"';
	}
}


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Output>, L<ETL::Pipeline::Output::UnitTest>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2016 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

# Required by Perl to load the module.
1;
