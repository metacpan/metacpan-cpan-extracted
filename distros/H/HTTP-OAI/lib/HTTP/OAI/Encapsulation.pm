package HTTP::OAI::Encapsulation;

use strict;
use warnings;

use HTTP::OAI::SAXHandler qw( :SAX );

use vars qw(@ISA);
@ISA = qw(XML::SAX::Base);

our $VERSION = '4.10';

sub new {
	my $class = shift;
	my %args = @_ > 1 ? @_ : (dom => shift);
	my $self = bless {}, ref($class) || $class;
	$self->version($args{version});
	$self->dom($args{dom});
	$self;
}

sub dom { shift->_elem('dom',@_) }

# Pseudo HTTP::Response
sub code { 200 }
sub message { 'OK' }

sub is_info { 0 }
sub is_success { 1 }
sub is_redirect { 0 }
sub is_error { 0 }

sub version { shift->_elem('version',@_) }

sub _elem {
	my $self = shift;
	my $name = shift;
	return @_ ? $self->{_elem}->{$name} = shift : $self->{_elem}->{$name};
}

sub _attr {
	my $self = shift;
	my $name = shift or return $self->{_attr};
	return $self->{_attr}->{$name} unless @_;
	if( defined(my $value = shift) ) {
		return $self->{_attr}->{$name} = $value;
	} else {
		delete $self->{_attr}->{$name};
		return undef;
	}
}

package HTTP::OAI::Encapsulation::DOM;

use strict;
use warnings;

use XML::LibXML qw( :all );

use vars qw(@ISA);
@ISA = qw(HTTP::OAI::Encapsulation);

sub toString { defined($_[0]->dom) ? $_[0]->dom->toString : undef }

sub generate {
	my $self = shift;
	unless( $self->dom ) {
		Carp::confess("Can't generate() without a dom.");
	}
	unless( $self->dom->nodeType == XML_DOCUMENT_NODE ) {
		Carp::confess( "Can only generate() from a DOM of type XML_DOCUMENT_NODE" );
	}
	return unless defined($self->get_handler);
	my $driver = XML::LibXML::SAX::Parser->new(
			Handler=>HTTP::OAI::FilterDOMFragment->new(
				Handler=>$self->get_handler
	));
	$driver->generate($self->dom);
}

sub start_document {
	my ($self) = @_;
HTTP::OAI::Debug::sax( ref($self) );
	my $builder = XML::LibXML::SAX::Builder->new() or die "Unable to create XML::LibXML::SAX::Builder: $!";
	$self->{OLDHandler} = $self->get_handler();
	$self->set_handler($builder);
	$self->SUPER::start_document();
	$self->SUPER::xml_decl({'Version'=>'1.0','Encoding'=>'UTF-8'});
}

sub end_document {
	my ($self) = @_;
	$self->SUPER::end_document();
	$self->dom($self->get_handler->result());
	$self->set_handler($self->{OLDHandler});
HTTP::OAI::Debug::sax( ref($self) . " <" . $self->dom->documentElement->nodeName . " />" );
}

1;

__END__

=head1 NAME

HTTP::OAI::Encapsulation - Base class for data objects that contain DOM trees

=head1 DESCRIPTION

This class shouldn't be used directly, use L<HTTP::OAI::Metadata>.

=cut
