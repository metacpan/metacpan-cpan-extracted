package HTTP::OAI::SAXHandler;

use strict;
use warnings;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use Data::Dumper; # debugging for here

our $VERSION = '4.12';

@ISA = qw( Exporter XML::SAX::Base );

@EXPORT_OK = qw( g_start_document g_start_element g_end_element g_data_element );
%EXPORT_TAGS = (SAX=>[qw( g_start_document g_start_element g_end_element g_data_element )]);

=pod

=head1 NAME

HTTP::OAI::SAXHandler - SAX2 utility filter

=head1 DESCRIPTION

This module provides utility methods for SAX2, including collapsing multiple "characters" events into a single event.

This module exports methods for generating SAX2 events with Namespace support. This *isn't* a fully-fledged SAX2 generator!

=over 4

=item $h = HTTP::OAI::SAXHandler->new()

Class constructor.

=cut

sub new {
	my ($class,%args) = @_;
	$class = ref($class) || $class;
	my $self = $class->SUPER::new(%args);
	$self->{Depth} = 0;
	$self;
}

sub g_start_document {
	my ($handler) = @_;
	$handler->start_document();
	$handler->start_prefix_mapping({
			'Prefix'=>'xsi',
			'NamespaceURI'=>'http://www.w3.org/2001/XMLSchema-instance'
	});
	$handler->start_prefix_mapping({
			'Prefix'=>'',
			'NamespaceURI'=>'http://www.openarchives.org/OAI/2.0/'
	});
}

sub g_data_element {
	my ($handler,$uri,$qName,$attr,$value) = @_;
	g_start_element($handler,$uri,$qName,$attr);
	if( ref($value) ) {
		$value->set_handler($handler);
		$value->generate;
	} else {
		$handler->characters({'Data'=>$value});
	}
	g_end_element($handler,$uri,$qName);
}

sub g_start_element {
	my ($handler,$uri,$qName,$attr) = @_;
	$attr ||= {};
	my ($prefix,$localName) = split /:/, $qName;
	unless(defined($localName)) {
		$localName = $prefix;
		$prefix = '';
	}
	$handler->start_element({
		'NamespaceURI'=>$uri,
		'Name'=>$qName,
		'Prefix'=>$prefix,
		'LocalName'=>$localName,
		'Attributes'=>$attr
	});
}

sub g_end_element {
	my ($handler,$uri,$qName) = @_;
	my ($prefix,$localName) = split /:/, $qName;
	unless(defined($localName)) {
		$localName = $prefix;
		$prefix = '';
	}
	$handler->end_element({
		'NamespaceURI'=>$uri,
		'Name'=>$qName,
		'Prefix'=>$prefix,
		'LocalName'=>$localName,
	});
}

sub current_state {
	my $self = shift;
	return $self->{State}->[$#{$self->{State}}];
}

sub current_element {
	my $self = shift;
	return $self->{Elem}->[$#{$self->{Elem}}];
}

sub start_document {
HTTP::OAI::Debug::sax( Dumper($_[1]) );
	$_[0]->SUPER::start_document();
}

sub end_document {
	$_[0]->SUPER::end_document();
HTTP::OAI::Debug::sax( Dumper($_[1]) );
}

# Char data is rolled together by this module
sub characters {
	my ($self,$hash) = @_;
	$self->{Text} .= $hash->{Data};
# characters are traced in {start,end}_element
#HTTP::OAI::Debug::sax( "'" . substr($hash->{Data},0,40) . "'" );
}

sub start_element {
	my ($self,$hash) = @_;
	push @{$self->{Attributes}}, $hash->{Attributes};

	# Call characters with the joined character data
	if( defined($self->{Text}) )
	{
HTTP::OAI::Debug::sax( "'".substr($self->{Text},0,40) . "'" );
		$self->SUPER::characters({Data=>$self->{Text}});
		$self->{Text} = undef;
	}

	$hash->{State} = $self;
	$hash->{Depth} = ++$self->{Depth};
HTTP::OAI::Debug::sax( (" " x $hash->{Depth}) . '<'.$hash->{Name}.'>' );
	$self->SUPER::start_element($hash);
}

sub end_element {
	my ($self,$hash) = @_;

	# Call characters with the joined character data
	$hash->{Text} = $self->{Text};
	if( defined($self->{Text}) )
	{
		# Trailing whitespace causes problems
		if( $self->{Text} =~ /\S/ )
		{
HTTP::OAI::Debug::sax( "'".substr($self->{Text},0,40) . "'" );
			$self->SUPER::characters({Data=>$self->{Text}});
		}
		$self->{Text} = undef;
	}

	$hash->{Attributes} = pop @{$self->{Attributes}} || {};
	$hash->{State} = $self;
	$hash->{Depth} = $self->{Depth}--;
HTTP::OAI::Debug::sax( (" " x $hash->{Depth}) . '  <'.$hash->{Name}.'>' );
	$self->SUPER::end_element($hash);
}

sub entity_reference {
	my ($self,$hash) = @_;
HTTP::OAI::Debug::sax( $hash->{Name} );
}

sub start_cdata {
HTTP::OAI::Debug::sax();
}

sub end_cdata {
HTTP::OAI::Debug::sax();
}

sub comment {
HTTP::OAI::Debug::sax( $_[1]->{Data} );
}

sub doctype_decl {
	# {SystemId,PublicId,Internal}
HTTP::OAI::Debug::sax( $_[1]->{Name} );
}

sub attlist_decl {
	# {ElementName,AttributeName,Type,Default,Fixed}
HTTP::OAI::Debug::sax( $_[1]->{ElementName} );
}

sub xml_decl {
	# {Version,Encoding,Standalone}
HTTP::OAI::Debug::sax( join ", ", map { defined($_) ? $_ : "null" } @{$_[1]}{qw( Version Encoding Standalone )} );
}

sub entity_decl {
	# {Value,SystemId,PublicId,Notation}
HTTP::OAI::Debug::sax( $_[1]->{Name} );
}

sub unparsed_decl {
HTTP::OAI::Debug::sax();
}

sub element_decl {
	# {Model}
HTTP::OAI::Debug::sax( $_[1]->{Name} );
}

sub notation_decl {
	# {Name,Base,SystemId,PublicId}
HTTP::OAI::Debug::sax( $_[1]->{Name} );
}

sub processing_instruction {
	# {Target,Data}
HTTP::OAI::Debug::sax( $_[1]->{Target} . " => " . $_[1]->{Data} );
}

package HTTP::OAI::FilterDOMFragment;

use vars qw( @ISA );

@ISA = qw( XML::SAX::Base );

# Trap things that don't apply to a balanced fragment
sub start_document {}
sub end_document {}
sub xml_decl {}

package XML::SAX::Debug;

use Data::Dumper;

use vars qw( @ISA $AUTOLOAD );

@ISA = qw( XML::SAX::Base );

sub DEBUG {
	my ($event,$self,$hash) = @_;
warn "$event(".Dumper($hash).")\n";
	my $superior = "SUPER::$event";
	$self->$superior($hash);
}

sub start_document { DEBUG('start_document',@_) }
sub end_document { DEBUG('end_document',@_) }
sub start_element { DEBUG('start_element',@_) }
sub end_element { DEBUG('end_element',@_) }
sub characters { DEBUG('characters',@_) }
sub xml_decl { DEBUG('xml_decl',@_) }

1;

__END__

=back

=head1 AUTHOR

Tim Brody <tdb01r@ecs.soton.ac.uk>
