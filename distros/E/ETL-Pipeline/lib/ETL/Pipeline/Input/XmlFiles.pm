=pod

=head1 NAME

ETL::Pipeline::Input::XmlFiles - Process XML content from individual files

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['XmlFiles', iname => qr/\.xlsx$/i, records_at => '/Xml'],
    mapping => {First => '/File/A', Second => '/File/Patient'},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::XmlFiles> defines an input source that reads one or more
records from one or more XML files. Most of the time, there should be one record
per file. But the class handles multiple records per file too.

=cut

package ETL::Pipeline::Input::XmlFiles;

use 5.014000;
use warnings;

use Carp;
use Data::DPath qw/dpath/;
use XML::Bare;
use Moose;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

=head3 records_at

Optional. The path to the record nodes, such as C</XMLDATA/Root/Record>. The
last item in the list is the name of the root for each individual record. The
default is B</> - one record in the file.

You might use this attribute in two cases...

=over

=item 1. Multiple records per file. This is the top of each record, like in L<ETL::Pipeline::Input::Xml>.

=item 2. Shorthand to leave off extra nodes from every path. One record per file, but you don't want extra path parts on the beginning of every field.

=back

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

	while (my $path = $self->next_path( $etl )) {
		# Load the XML file and turn it into a Perl hash.
		my $parser = XML::Bare->new( file => "$path" );
		my $xml = $parser->parse;

		# Find the node that is an array of records. dpath should return a list
		# with one array reference. And that array has the actual records. But I
		# check, just in case your XML is structured a little differently.
		#
		# XML should generate hashes - field/value pairs. In theory, there might
		# be an XML file that sends back a single record as an array reference.
		# Not likely when transfering data.
		my @matches = dpath( $self->records_at )->match( $xml );
		my $list = (scalar( @matches ) == 1 && ref( $matches[0] ) eq 'ARRAY') ? $matches[0] : \@matches;

		# Process each record. And that's it.
		my $source = $self->source;
		foreach my $record (@$list) {
			$self->source( sprintf( '%s character %d', $source, $record->{_pos} ) );
			$etl->record( $record );
		}
	}
}


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::File::List>,
L<XML::Bare>

=cut

with 'ETL::Pipeline::Input';
with 'ETL::Pipeline::Input::File::List';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
