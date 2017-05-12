=pod

=head1 NAME

ETL::Pipeline::Input::Xml - Records from an XML file

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['Xml', matching => 'Data.xml', root => '/Root'],
    mapping => {Name => 'Name', Address => 'Address'},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::Xml> defines an input source that reads records from an
XML file. Individual records are found under the L</root> node. Fields are
accessed with a relative XML path.

=cut

package ETL::Pipeline::Input::Xml;
use Moose;

use 5.014000;
use warnings;

use Carp;
use List::Util qw/first/;
use String::Util qw/hascontent trim/;
use XML::XPath;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

=head3 root

The B<root> attribute holds the XPath for the top node. L</next_record>
iterates over B<root>'s children.

=cut

has 'root' => (
	is  => 'ro',
	isa => 'Str',
);


=head2 Called from L<ETL::Pipeline/process>

=head3 get

B<get> returns a list of values from matching nodes. The field name is an 
I<XPath>, relative to L</root>. See 
L<http://www.w3schools.com/xpath/xpath_functions.asp> for more information on 
XPaths.

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
  $etl->get( 'Name' );
  'John Doe'
  
  # Return a list from multiple fields with the same name.
  $etl->get( 'PersonInvolved/Name' );
  ('John Doe', 'Jane Doe')
  
  # Return a list from subnodes.
  $etl->get( 'PersonInvolved', 'Name' );
  ('John Doe', 'Jane Doe')
  
  # Return a list of related fields from subnodes.
  $etl->get( 'PersonInvolved', 'Name', 'Role' );
  (['John Doe', 'Husband'], ['Jane Doe', 'Wife'])

In the L<ETL::Pipeline/mapping>, those examples looks like this...

  {Name => 'Name'}
  {Name => 'PersonInvolved/Name'}
  {Name => ['PersonInvolved', 'Name']}
  {Name => ['PersonInvolved', 'Name', 'Role']}

=cut

sub get {
	my ($self, $top, @subnodes) = @_;
	my $xpath = $self->xpath;

	my $match = $xpath->find( $top, $self->current );
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

	my $return = undef;
	until (defined $return) {
		my $next = $self->node_set->shift();
		if (not defined $next) {
			$return = 0;
		} elsif ($next->isa( 'XML::XPath::Node::Element' )) {
			$self->_set_current( $next );
			$return = 1;
		}
	}
	return $return;
}


=head3 configure

B<configure> opens the XML file and extracts the node set. L</next_record> then
iterates over the node set.

=cut

sub configure {
	my ($self) = @_;

	my $file = $self->file;
	my $root = $self->root;

	my $parser = XML::XPath->new( filename => "$file" );
	my $node_set = $parser->findnodes( $root );
	croak "Cannot find $root in $file" unless defined $node_set;

	$self->_set_xpath( $parser );
	$self->_set_node_set( $node_set );
}


=head3 finish

B<finish> doesn't actually do anything. But it is required by
L<ETL::Pipeline/process>. 

=cut

sub finish { }


=head2 Other Methods & Attributes

=head3 attribute

The B<attribute> method returns the value of an attribute on the root node.
For example, deleted records may have an attribute like C<ACTION="DELETE">. 
L<ETL::Pipeline::Input/skip_if> can use B<attribute> and bypass these records.

  $elt->input( 'Xml',
      bypass_if => sub { $_->input->attribute( 'ACTION' ) eq 'DELETE' },
      matching  => 'Data.xml',
      root_node => '/File'
  );

=cut

sub attribute {
	my ($self, $name) = @_;
	return $self->current->getAttribute( $name );
}


=head3 current

The B<current> attribute holds the currently selected node (record). 
L</next_record> automatically sets B<current>.

=cut

has 'current' => (
	init_arg => undef,
	is       => 'ro',
	isa      => 'XML::XPath::Node::Element',
	writer   => '_set_current',
);


=head3 node_set

The B<node_set> attribute holds the node set of records. It is the list of 
records in this file. L</configure> automatically sets B<node_set>.

=cut

has 'node_set' => (
	init_arg => undef,
	is       => 'ro',
	isa      => 'XML::XPath::NodeSet',
	writer   => '_set_node_set',
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

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::File>,
L<XML::XPath>

=cut

with 'ETL::Pipeline::Input::File';
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
