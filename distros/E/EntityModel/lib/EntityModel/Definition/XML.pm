package EntityModel::Definition::XML;
{
  $EntityModel::Definition::XML::VERSION = '0.102';
}
use EntityModel::Class {
	_isa		=> [qw{EntityModel::Definition}],
};

=head1 NAME

EntityModel::Definition::XML - definition support for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

=head1 METHODS

=cut

use XML::XPath;
use XML::XPath::Node;

=head2 load_file

=cut

sub load_file {
	my $self = shift;
	my $path = shift;

	my $xml = XML::XPath->new(filename => $path)
	 or die 'Unable to load ' . $self . ' from data source ' . $path;
	return $self->parse($xml);
}

=head2 load_string

=cut

sub load_string {
	my $self = shift;
	my $string = shift;

	my $xml = XML::XPath->new(xml => $string)
	 or die 'Unable to load ' . $self . ' from data source ' . $string;
	return $self->parse($xml);
}

=head2 parse

Parse the L<XML::XPath> object.

=cut

sub parse {
	my $self = shift;
	my $xml = shift;
	my $ns = $xml->find('/entitymodel') // [];
	my ($structure) = map { $self->parseNode($_) } @$ns;
	return $structure;
}

=head2 parseNode

Parse an individual node in the tree.

=cut

sub parseNode {
	my $self = shift;
	my $node = shift;
	my $name = $node->getName;

# Locate all child nodes (eliminating whitespace and other text nodes)
	my @child = grep { $_->getName } $node->getChildNodes;

	my %name;
	foreach my $c (@child) {
		my $grandchildCount = scalar(grep { $_->getName } $c->getChildNodes);
		if($grandchildCount) {
			push @{$name{$c->getName}}, $self->parseNode($c);
		} else {
			$name{$c->getName} = $c->string_value;
		}
	}
	return \%name;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
