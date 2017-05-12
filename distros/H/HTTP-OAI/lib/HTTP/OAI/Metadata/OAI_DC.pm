package HTTP::OAI::Metadata::OAI_DC;

@ISA = qw( HTTP::OAI::MemberMixin HTTP::OAI::SAX::Base );

use strict;

our $VERSION = '4.04';

our $OAI_DC_SCHEMA = 'http://www.openarchives.org/OAI/2.0/oai_dc/';
our $DC_SCHEMA = 'http://purl.org/dc/elements/1.1/';
our @DC_TERMS = qw( contributor coverage creator date description format identifier language publisher relation rights source subject title type );
our %VALID_TERM = map { $_ => 1 } @DC_TERMS;

sub metadata { shift->dom(@_) }

sub dc { shift->_elem('dc',@_) }

sub generate
{
	my( $self, $driver ) = @_;

	$driver->start_element( 'metadata' );
	$driver->start_element( 'oai_dc:dc',
		'xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
		'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
		'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
		'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd',
	);
	foreach my $term (@DC_TERMS)
	{
		foreach my $value (@{$self->{dc}{$term} || []})
		{
			$driver->data_element( "dc:$term", $value );
		}
	}
	$driver->end_element( 'oai_dc:dc' );
	$driver->end_element( 'metadata' );
}

sub _toString {
	my $self = shift;
	my $str = "Open Archives Initiative Dublin Core (".ref($self).")\n";
	foreach my $term ( @DC_TERMS )
	{
		for(@{$self->{dc}->{$term}})
		{
			$str .= sprintf("%s:\t%s\n", $term, $_||'');
		}
	}
	$str;
}

sub end_element {
	my ($self,$hash) = @_;
	my $elem = lc($hash->{LocalName});
	if( $VALID_TERM{$elem} )
	{
		push @{$self->{dc}->{$elem}}, $hash->{Text};
	}
}

1;

__END__

=head1 NAME

HTTP::OAI::Metadata::OAI_DC - Easy access to OAI Dublin Core

=head1 DESCRIPTION

HTTP::OAI::Metadata::OAI_DC provides a simple interface to parsing and generating OAI Dublin Core ("oai_dc").

=head1 SYNOPSIS

	use HTTP::OAI::Metadata::OAI_DC;

	my $md = new HTTP::OAI::Metadata(
		dc=>{title=>['Hello, World!','Hi, World!']},
	);

	# Prints "Hello, World!"
	print $md->dc->{title}->[0], "\n";

	my $xml = $md->metadata();

	$md->metadata($xml);

=head1 NOTE

HTTP::OAI::Metadata::OAI_DC will automatically (and silently) convert OAI version 1.x oai_dc records into OAI version 2.0 oai_dc records.
