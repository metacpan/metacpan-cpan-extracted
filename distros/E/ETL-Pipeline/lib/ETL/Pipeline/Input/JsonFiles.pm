=pod

=head1 NAME

ETL::Pipeline::Input::JsonFiles - Process JSON content from individual files

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['JsonFiles', iname => qr/\.json$/i, records_at => '/json'],
    mapping => {First => '/File/A', Second => '/File/Patient'},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::JsonFiles> defines an input source that reads one or
more records from one or more JSON files. Most of the time, there should be one
record per file. But the class handles multiple records per file too.

=cut

package ETL::Pipeline::Input::JsonFiles;

use 5.014000;
use warnings;

use Carp;
use Data::DPath qw/dpath/;
use JSON;
use Moose;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

=head3 records_at

Optional. The path to the record nodes, such as C</json/Record>. The
last item in the list is the name of the root for each individual record. The
default is B</> - one record in the file.

You might use this attribute in two cases...

=over

=item 1. Multiple records per file. This is the top of each record, like in L<ETL::Pipeline::Input::Xml>.

=item 2. Shorthand to leave off extra nodes from every path. One record per file, but you don't want extra path parts on the beginning of every field.

=back

This can be any value accepted by L<Data::DPath>.

=cut

has 'records_at' => (
	default => '/',
	is      => 'ro',
	isa     => 'Str',
);


=head3 skipping

Not used. This attribute is ignored. JSON files must follow specific formatting
rules. Extra rows are parsed as data. There's nothing to skip.

=head2 Methods

=head3 run

This is the main loop. It opens the file, reads records, and closes it when
done. This is the place to look if there are problems.

L<ETL::Pipeline> automatically calls this method.

=cut

sub run {
	my ($self, $etl) = @_;

	my $parser = JSON->new->utf8;
	while (my $path = $self->next_path( $etl )) {
		my $text = $path->slurp;	# Force scalar context, otherwise slurp breaks it into lines.
		my $json = $parser->decode( $text );
		croak "JSON file '$path', unable to parse" unless defined $json;

		# Find the node that is an array of records. This comes from the
		# "records_at" attribute.
		#
		# I assume that records are field/value pairs - a Perl hash. So if the
		# DPath matches an array, it is an array of record. I need to
		# de-reference that list to get to the actual records.
		my @matches = dpath( $self->records_at )->match( $json );
		my $list = (scalar( @matches ) == 1 && ref( $matches[0] ) eq 'ARRAY') ? $matches[0] : \@matches;

		# Process each record. And that's it. The record is a Perl data
		# structure corresponding with the JSON structure.
		$etl->record( $_ ) foreach (@$list);
	}
}


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::File::List>,
L<JSON>

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
