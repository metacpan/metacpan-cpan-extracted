=pod

=head1 NAME

ETL::Pipeline::Input::Xml - Records from an XML file

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['Xml', iname => 'Data.xml', root => '/Root'],
    mapping => {Name => 'Name', Address => 'Address'},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::Xml> defines an input source that reads multiple records
from a single XML file. Individual records are repeating subnodes under
L</root>.

=cut

package ETL::Pipeline::Input::Xml;

use 5.014000;
use warnings;

use Carp;
use Data::DPath qw/dpath/;
use Moose;
use XML::Bare;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

=head3 records_at

Required. The path to the record nodes, such as C</XMLDATA/Root/Record>. The
last item in the list is the name of the root for each individual record. The
code loops over all of these nodes.

This can be any value accepted by L<Data::DPath>. Fortunately, L<Data::Dpath>
takes paths that look like XPath for XML.

=cut

has 'records_at' => (
	default => '/',
	is      => 'ro',
	isa     => 'Str',
);


=head3 skipping

Not used. This attribute is ignored. XML files must follow specific formatting
rules. Extra rows are parsed as data. There's nothing to skip.

=head2 Methods

=head3 run

This is the main loop. It opens the file, reads records, and closes it when
done. This is the place to look if there are problems.

L<ETL::Pipeline> automatically calls this method.

=cut

sub run {
	my ($self, $etl) = @_;

	my $path = $self->path;

	# Load the XML file and turn it into a Perl hash.
	my $parser = XML::Bare->new( file => "$path" );
	my $xml = $parser->parse;

	# Find the node that is an array of records. dpath should return a list with
	# one array reference. And that array has the actual records. But I check,
	# just in case your XML is structured a little differently.
	#
	# XML should generate hashes - field/value pairs. In theory, there might be
	# an XML file that sends back a single record as an array reference. Not
	# likely when transfering data.
	my @matches = dpath( $self->records_at )->match( $xml );
	my $list = (scalar( @matches ) == 1 && ref( $matches[0] ) eq 'ARRAY') ? $matches[0] : \@matches;

	# Process each record. And that's it.
	my $source = $self->source;
	foreach my $record (@$list) {
		$self->source( sprintf( '%s character %d', $source, $record->{_pos} ) );
		$etl->record( $record );
	}
}


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::File>,
L<XML::Bare>

=cut

with 'ETL::Pipeline::Input';
with 'ETL::Pipeline::Input::File';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
