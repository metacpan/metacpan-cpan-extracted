=pod

=head1 NAME

ETL::Pipeline::Output::Memory - Save records in memory

=head1 SYNOPSIS

  # Save the records into a giant list.
  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['UnitTest'],
    mapping => {First => 'Header1', Second => 'Header2'},
    output  => ['Memory']
  } )->process;

  # Save the records into a hash, keyed by an identifier.
  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['UnitTest'],
    mapping => {First => 'Header1', Second => 'Header2'},
    output  => ['Memory', key => 'First']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Output::Memory> writes the record into a Perl data structure,
in memory. The records can be accessed later in the same script.

This output destination comes in useful when processing multiple input files.

=head2 Internal data structure

B<ETL::Pipeline::Output::Memory> offers two ways of storing the records - in
a hash or in a list. B<ETL::Pipeline::Output::Memory> automatically chooses
the correct one depending on the L</key> attribute.

When L</key> is set, B<ETL::Pipeline::Output::Memory> saves the records in a
hash, keyed by the given field. This allows for faster look-up. Use L</key>
when the record has an identifier.

When L</key> is not set, B<ETL::Pipeline::Output::Memory> saves the record in
a list. The list saves records unordered - first in first out.

=cut

package ETL::Pipeline::Output::Memory;
use Moose;

use 5.14.0;
use warnings;

use Carp;
use String::Util qw/hascontent/;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/output>

=head3 key

The L</current> record is stored as a Perl hash. B<key> is the output
destination field name that ties this record with whatever other data you have.
In short, B<key> is the identifier field.

B<key> can be blank. In that case, records are stored in L</list>, unsorted.

=cut

has 'key' => (
	default => '',
	is      => 'ro',
	isa     => 'Str',
);


=head2 Called from L<ETL::Pipeline/process>

=head3 write_record

B<write_record> copies the contents of L</current> into L</hash> or L</list>,
saving the record into memory. You can retrieve the records later using the 
L</with_id> or L</records> methods.

=cut

sub write_record {
	my $self = shift;
	my $key = $self->key;

	# Key field = hash
	# No key field = list
	my $list;
	if (hascontent( $key )) {
		# NULL is an invalid key. Empty strings are okay, though. If the data
		# has NULLs, then your script should translate them.
		my $id = $self->get_value( $key );
		return $self->error( "The field '$key' was not set" ) unless defined $id;

		$list = $self->with_id( $id );
		unless (defined $list) {
			$list = [];
			$self->_add_to_id( $id, $list );
		}
	} else { $list = $self->list; }

	# "new_record" creates a brand new reference. So it's safe to store this
	# reference without making a copy.
	push @$list, $self->current;

	return 1;
}


=head3 configure

B<configure> doesn't actually do anything. But it is required by
L<ETL::Pipeline/process>.

=cut

sub configure {}


=head3 finish

B<finish> doesn't actually do anything. But it is required by
L<ETL::Pipeline/process>.

=cut

sub finish {}


=head2 Other methods and attributes

=head3 with_id

B<with_id> returns a list of records for the given key. Pass in a value for the
key and B<with_id> returns an array reference of records.

B<with_id> only works if the L</key> attribute was set.

=head3 hash

B<hash> is a hash reference used when L</key> is set. The key is the value
of the field idnetified by L</key>. The value is an array reference. The array
contains all of the records with that same key.

=cut

has 'hash' => (
	default => sub { {} },
	handles => {_add_to_id => 'set', number_of_ids => 'count', with_id => 'get'},
	is      => 'ro',
	isa     => 'HashRef[ArrayRef[HashRef[Any]]]',
	traits  => [qw/Hash/],
);


=head3 records

B<records> returns a list of hash references. Each hash reference is one data 
record. B<records> only works when the L</key> attribute is blank.

=head3 list

B<list> is an array reference that stores records. The records are saved in
same order as they are read from the input source. Each list element is a
hash reference (the record).

=cut

has 'list' => (
	default => sub { [] },
	handles => {number_of_records => 'count', records => 'elements'},
	is      => 'ro',
	isa     => 'ArrayRef[HashRef[Any]]',
	traits  => [qw/Array/],
);


=head3 default_fields

Initialize L</current> for the next record.

=cut

sub default_fields { () }


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Output>, 
L<ETL::Pipeline::Output::Storage::Hash>

=cut

with 'ETL::Pipeline::Output::Storage::Hash';
with 'ETL::Pipeline::Output';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2016 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
