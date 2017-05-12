package HTML::MobileJp::Filter::Content;
use Any::Moose;

has _current => (
    is      => 'rw',
    isa     => 'Any',
);

has html => (
    is      => 'rw',
    isa     => 'Str',
    trigger => sub {
        shift->_current('html');
    },
);

has xml => (
    is      => 'rw',
    isa     => 'XML::LibXML::Document',
    trigger => sub {
        shift->_current('xml');
    },
);

use overload '""' => 'stringfy', fallback => 1;

*stringfy = \&as_html;

use XML::LibXML;

sub update {
    my ($self, $content) = @_;
    if (ref($content) and $content->isa(__PACKAGE__)) {
        $self->{$_} = $content->{$_} for qw( html xml );
    } elsif (ref($content) and $content->isa('XML::LibXML::Document')) {
        $self->xml($content);
    } else {
        $self->html($content);
    }
}

sub as_html {
    my ($self) = @_;
    if ($self->_current ne 'html') {
        $self->html( $self->xml->toString ) if $self->_current ne 'html';
    }
    $self->html;
}

sub as_xml {
    my ($self) = @_;
    if ($self->_current ne 'xml') {
        $self->xml( XML::LibXML->new->parse_string($self->html) );
    }
    $self->xml;
}

__PACKAGE__->meta->make_immutable;
1;
