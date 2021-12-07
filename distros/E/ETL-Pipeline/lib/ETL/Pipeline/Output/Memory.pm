=pod

=head1 NAME

ETL::Pipeline::Output::Memory - Store records in memory

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
in memory. The records can be accessed later in the same script. This output
destination comes in useful when processing multiple input files.

B<ETL::Pipeline::Output::Memory> offers two ways of storing the records - in
a hash or in a list. B<ETL::Pipeline::Output::Memory> always put records into
the list. If the L</key> attribute is set, then B<ETL::Pipeline::Output::Memory>
also saves records into the hash.

The hash can be used for faster look-up. Use L</key> when the record contains an
identifier.

=cut

package ETL::Pipeline::Output::Memory;

use 5.014000;
use warnings;

use Moose;
use String::Util qw/hascontent/;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/output>

=head3 key

Optional. If you want to store the records in a hash, then this is the field
name whose value becomes the key. When set, records go into L</hash>.

If you don't specify a B<key>, then records are stored in an unsorted array -
L</list>.

=cut

has 'key' => (
	default => '',
	is      => 'ro',
	isa     => 'Str',
);


=head2 Attributes

=head3 hash

Hash reference used when L</key> is set. The key is the value of the field
identified by L</key>. The value is an array reference. The array contains all
of the records with that same key.

=cut

has 'hash' => (
	default => sub { {} },
	handles => {
		_add_to_id    => 'set',
		number_of_ids => 'count',
		with_id       => 'get',
	},
	is      => 'ro',
	isa     => 'HashRef[ArrayRef[HashRef[Any]]]',
	traits  => [qw/Hash/],
);


=head3 list

B<list> is an array reference that stores records. The records are saved in
same order as they are read from the input source. Each list element is a
hash reference (the record).

B<list> always has a complete set of records, whether L</key> is set or not.

=cut

has 'list' => (
	default => sub { [] },
	handles => {
		_add_record       => 'push',
		number_of_records => 'count',
		records           => 'elements',
	},
	is      => 'ro',
	isa     => 'ArrayRef[HashRef[Any]]',
	traits  => [qw/Array/],
);


=head2 Methods

=head3 close

This method doesn't do anything. There's nothing to close or shut down.

=cut

sub close {}


=head3 number_of_ids

Count of unique identifiers. This may not be the same as the number of records.
One key may have multiple records.

B<number_of_ids> only works if the L</key> attribute was set.


=cut

# This method is defined by the "hash" attribute.


=head3 number_of_records

Count of records currently in storage.

=cut

# This method is defined by the "list" attribute.


=head3 open

This method doesn't do anything. There's nothing to open or setup.

=cut

sub open {}


=head3 records

Returns a list of all the records currently in storage. The list contains hash
references - one reference for each record.

=cut

# This method is defined by the "list" attribute.


=head3 with_id

B<with_id> returns a list of records for a given key. Pass in a value for the
key and B<with_id> returns an array reference of records.

B<with_id> only works if the L</key> attribute was set.

=cut

# This method is defined by the "hash" attribute.


=head3 write

Save the current record into memory. Your script can access the records after
calling L<ETL::Pipeline/process> like this - C<$etl->output->records>.
Both L</records> and L</with_id> can be used.

If L</key> is set, B<write> saves the record in both L</hash> and L</list>.
We're storing a reference, not a copy, so there's very little cost. And it
allows methods such as L</number_of_records> to work.

B<WARNING:> This method stores a I<reference> to the original record. If the
input source re-uses the hash or embedded references, it will update all of the
currently stored values too. B<ETL::Pipeline::Output::Memory> does not make a
copy.

=cut

sub write {
	my ($self, $etl, $record) = @_;
	my $key = $self->key;

	# Key field = hash
	# No key field = list
	my $list;
	if (hascontent( $key )) {
		# NULL is an invalid key. Empty strings are okay, though. If the data
		# has NULLs, then your script should translate them.
		my $id = $record->{$key};
		return $etl->log( 'ERROR', "The field '$key' was undefined" )
			unless defined $id;

		$list = $self->with_id( $id );
		unless (defined $list) {
			$list = [];
			$self->_add_to_id( $id, $list );
		}
		push @$list, $record;
	}
	$self->_add_record( $record );
}


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Output>

=cut

with 'ETL::Pipeline::Output';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
