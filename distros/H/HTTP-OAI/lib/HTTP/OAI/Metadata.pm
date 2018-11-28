package HTTP::OAI::Metadata;

@ISA = qw( HTTP::OAI::MemberMixin HTTP::OAI::SAX::Base );

use strict;

our $VERSION = '4.08';

sub new
{
	my( $class, %self ) = @_;

    my $inst = bless \%self, $class;

    if ($self{dom}) {
        $inst->_elem("dom", $self{dom});
    }
    else {
        $inst->{doc} = XML::LibXML::Document->new( '1.0', 'UTF-8' );
        $inst->{dom} = $inst->{current} = $inst->{doc}->createDocumentFragment;
    }

	return $inst;
}

sub metadata { shift->dom( @_ ) }
sub dom { shift->_elem( "dom", @_ ) }

sub generate
{
	my( $self, $driver ) = @_;

	$driver->generate( $self->dom );
}

sub start_element
{
	my( $self, $hash ) = @_;

	my $node = $self->{doc}->createElementNS(
		$hash->{NamespaceURI},
		$hash->{Name},
	);
	foreach my $attr (values %{$hash->{Attributes}})
	{
		Carp::confess "Can't setAttribute without attribute name" if !defined $attr->{Name};
		$node->setAttribute( $attr->{Name}, $attr->{Value} );
	}

	$self->{current} = $self->{current}->appendChild( $node );
}

sub end_element
{
	my( $self, $hash ) = @_;

	$self->{current} = $self->{current}->parentNode;
}

sub characters
{
	my( $self, $hash ) = @_;

	$self->{current}->appendText( $hash->{Data} );
}

1;

__END__

=head1 NAME

HTTP::OAI::Metadata - Base class for data objects that contain DOM trees

=head1 SYNOPSIS

	use HTTP::OAI::Metadata;

	$xml = XML::LibXML::Document->new();
	$xml = XML::LibXML->new->parse( ... );

    $md = new HTTP::OAI::Metadata();

    $md->dom($xml);

	$md = new HTTP::OAI::Metadata(dom=>$xml);

	print $md->dom->toString;

	my $dom = $md->dom(); # Return internal DOM tree

=head1 METHODS

=over 4

=item $md->dom( [$dom] )

Return and optionally set the XML DOM object that contains the actual metadata. If you intend to use the generate() method $dom must be a XML_DOCUMENT_NODE.

=back
