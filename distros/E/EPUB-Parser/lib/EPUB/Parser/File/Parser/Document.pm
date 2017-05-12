package EPUB::Parser::File::Parser::Document;
use strict;
use warnings;
use Carp;
use parent 'EPUB::Parser::File::Parser';

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    $self->set_namespace;

    return $self;
}

sub set_namespace {
    my $self = shift;
    $self->set_xhtml_namespace;
}

sub set_xhtml_namespace {
    my $self = shift;

    my $xhtml_ns = $self->{doc}->documentElement()->getAttribute('xmlns');
    $self->{parser}->registerNs( xhtml => $xhtml_ns );
}

1;

