package HTTP::OAI::SAX::Base;

@ISA = qw( XML::SAX::Base );

use strict;

our $VERSION = '4.05';

sub toString
{
	my $str = shift->dom->toString( 1 );
	utf8::decode($str);
	return $str;
}

sub parse_string
{
	my( $self, $string ) = @_;

	my $parser = XML::LibXML::SAX->new(
		Handler => HTTP::OAI::SAX::Text->new(
			Handler => $self,
		)
	);
	$parser->parse_string( $string );
}

sub parse_file
{
	my( $self, $fh ) = @_;

	my $parser = XML::LibXML::SAX->new(
		Handler => HTTP::OAI::SAX::Text->new(
			Handler => $self,
		)
	);
	$parser->parse_file( $fh );
}

sub generate
{
	my( $self, $driver ) = @_;

	# override this
}

sub dom {
	my $self = shift;
	if( my $dom = shift ) {
		my $driver = XML::LibXML::SAX::Parser->new(
			Handler=>HTTP::OAI::SAXHandler->new(
				Handler=>$self
		));
		$driver->generate($dom);
	} else {
		my $driver = HTTP::OAI::SAX::Driver->new(
				Handler => my $builder = XML::LibXML::SAX::Builder->new()
			);
		$driver->start_oai_pmh();
		$self->generate( $driver );
		$driver->end_oai_pmh();

		return $builder->result;
	}
}

1;
