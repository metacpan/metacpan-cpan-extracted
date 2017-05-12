=pod

=head1 NAME

ETL::Pipeline::Input::XmlFiles - Records in individual XML files

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['XmlFiles', from => 'Documents'],
    mapping => {Name => '/Root/Name', Address => '/Root/Address'},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::XmlFiles> defines an input source that reads multiple
XML files from a directory. Each XML file contains exactly one record. Fields
are accessed with the full XML path.

=cut

package ETL::Pipeline::Input::XmlFiles;
use Moose;

use 5.014000;
use warnings;

use Carp;
use MooseX::Types::Path::Class qw/Dir File/;
use Path::Class qw//;
use Path::Class::Rule;
use XML::XPath;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

=head3 from

B<from> tells B<ETL::Pipeline::Input::XmlFiles> where to find the data files. 
By default, B<ETL::Pipeline::Input::XmlFiles> looks in 
L<ETL::Pipeline/data_in>. B<from> tells the code to look in another place.

If B<from> is a regular expression, the code finds the first directory whose
name matches. If B<from> is a relative path, it is expected to reside under 
L<ETL::Pipeline/data_in>. An absolute path is exact.

=cut

has 'from' => (
	init_arg => undef,
	is       => 'bare',
	isa      => Dir,
	reader   => '_get_from',
	writer   => '_set_from',
);


sub from {
	my $self = shift;

	if (scalar( @_ ) > 0) {
		my $new = shift;
		if (ref( $new ) eq 'Regexp') {
			my $match = Path::Class::Rule->new
				->iname( $new )
				->max_depth( 1 )
				->directory
				->iter( $self->pipeline->data_in )
				->()
			;
			croak 'No matching directories' unless defined $match;
			$self->_set_from( $match );
		} else  {
			my $folder = Path::Class::dir( $new );
			$folder = $folder->absolute( $self->pipeline->data_in ) 
				if $folder->is_relative;
			$self->_set_from( $folder );
		}
	}
	return $self->_get_from;
}


=head3 ...

B<ETL::Pipeline::Input::XmlFiles> accepts any of the tests provided by
L<Path::Iterator::Rule>. The value of the argument is passed directly into the 
test. For boolean tests (e.g. readable, exists, etc.), pass an C<undef> value.

B<ETL::Pipeline::Input::XmlFiles> automatically applies the C<file> and
C<iname> filters. Do not pass C<file> through L<ETL::Pipeline/input>. You may
pass in C<name> or C<iname> to override the default filter of B<*.xml>.

=cut

sub BUILD {
	my $self = shift;
	my $arguments = shift;

	# Set the top level directory.
	if (defined $arguments->{from}) {
		$self->from( $arguments->{from} );
	} else { $self->from( '.' ); }

	# Configure the file search.
	my @criteria = grep { 
		$_ ne 'file' 
		&& !$self->meta->has_attribute( $_ ) 
	} keys %$arguments;
	my $search = Path::Class::Rule->new;
	foreach my $name (@criteria) {
		my $value = $arguments->{$name};
		eval "\$search->$name( \$value )";
		croak $@ unless $@ eq '';
	}
	$search->iname( '*.xml' ) 
		unless exists( $arguments->{name} ) || exists( $arguments->{iname} );
	$search->file;
	$self->_set_iterator( $search->iter( $self->from ) );
}


=head2 Called from L<ETL::Pipeline/process>

=head3 get

B<get> returns a list of values from matching nodes. The field name is an 
I<XPath>. See L<http://www.w3schools.com/xpath/xpath_functions.asp> for more
information on XPaths.

XML lends itself to recursive records. What happens when you need two fields
under the same subnode? For example, a I<person involved> can have both a 
I<name> and a I<role>. The names and roles go together. How do you B<get> them
together?

B<get> supports subnodes as additional parameters. Pass the top node as the
first parameter. Pass the subnode names in subsequent parameters. The values
are returned in the same order as the parameters. B<get> returns C<undef> for
any non-existant subnodes.

Here are some examples...

  # Return a single value from a single field.
  $etl->get( '/Root/Name' );
  'John Doe'
  
  # Return a list from multiple fields with the same name.
  $etl->get( '/Root/PersonInvolved/Name' );
  ('John Doe', 'Jane Doe')
  
  # Return a list from subnodes.
  $etl->get( '/Root/PersonInvolved', 'Name' );
  ('John Doe', 'Jane Doe')
  
  # Return a list of related fields from subnodes.
  $etl->get( '/Root/PersonInvolved', 'Name', 'Role' );
  (['John Doe', 'Husband'], ['Jane Doe', 'Wife'])

In the L<ETL::Pipeline/mapping>, those examples looks like this...

  {Name => '/Root/Name'}
  {Name => '/Root/PersonInvolved/Name'}
  {Name => ['/Root/PersonInvolved', 'Name']}
  {Name => ['/Root/PersonInvolved', 'Name', 'Role']}

=cut

sub get {
	my ($self, $top, @subnodes) = @_;
	my $xpath = $self->xpath;

	my $match = $xpath->find( $top );
	if ($match->isa( 'XML::XPath::NodeSet' )) {
		if (scalar( @subnodes ) == 0) {
			return map { $_->string_value } $match->get_nodelist;
		} elsif (scalar( @subnodes ) == 1) {
			my @values;
			foreach my $node ($match->get_nodelist) {
				my $data = $xpath->find( $subnodes[0], $node );
				push @values, $data->string_value;
			}
			return @values;
		} else {
			my @values;
			foreach my $node ($match->get_nodelist) {
				my @current;
				foreach my $path (@subnodes) {
					my $data = $xpath->find( $path, $node );
					push @current, $data->string_value;
				}
				push @values, \@current;
			}
			return @values;
		}
	} else { return $match->value; }
}


=head3 next_record

This method parses the next file in the folder.

B<Data::ETL::Extract::XmlFiles> builds a list of file names when it first
starts. B<next_record> iterates over this in-memory list. It will not parse
any new files saved into the folder.

=cut

sub next_record {
	my ($self) = @_;

	my $object = $self->_next_file;
	if (defined $object) {
		$self->_set_file( $object );

		my $parser = XML::XPath->new( filename => "$object" );
		croak "Unable to parse the XML in '$object'" unless defined $parser;
		$self->_set_xpath( $parser );

		return 1;
	} else { return 0; }
}


=head3 configure

B<configure> doesn't actually do anything. But it is required by
L<ETL::Pipeline/process>.

=cut

sub configure { }


=head3 finish

B<finish> doesn't actually do anything. But it is required by
L<ETL::Pipeline/process>. 

=cut

sub finish { }


=head2 Other Methods & Attributes

=head3 exists

The B<exists> method tells you whether the given path exists or not. It returns
a boolean value. B<True> means that the given node exists in this XML file.
B<False> means that it does not.

B<exists> accepts an XPath string as the only parameter. You can learn more 
about XPath here: L<http://www.w3schools.com/xpath/xpath_functions.asp>.

=cut

sub exists {
	my ($self, $xpath_string) = @_;

	my @matches = $self->xpath->findnodes( $xpath_string );
	return (scalar( @matches ) > 0 ? 1 : 0);
}


=head3 file

The B<file> attribute holds a L<Path::Class:File> object for the current XML
file. You can use it for accessing the file name or directory.

B<file> is automatically set by L</next_record>.

=cut

has 'file' => (
	init_arg => undef,
	is       => 'ro',
	isa      => File,
	writer   => '_set_file',
);


=head3 iterator

L<Path::Class::Rule> creates an iterator that returns each file in turn. 
B<iterator> holds it for L</next_record>.

=cut

has 'iterator' => (
	handles => {_next_file => 'execute'},
	is      => 'ro',
	isa     => 'CodeRef',
	traits  => [qw/Code/],
	writer  => '_set_iterator',
);


=head3 xpath

The B<xpath> attribute holds the current L<XML::XPath> object. It is 
automatically set by the L</next_record> method.

=cut

has 'xpath' => (
	init_arg => undef,
	is       => 'ro',
	isa      => 'XML::XPath',
	writer   => '_set_xpath',
);


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::XML>, 
L<Path::Class::File>, L<Path::Class::Rule>, L<Path::Iterator::Rule>, 
L<XML::XPath>

=cut

with 'ETL::Pipeline::Input';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2016 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
