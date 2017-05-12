package EPUB::Parser::File::Parser::OPF;
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
    $self->set_pkg_namespace;
    $self->set_metadata_namespace;
}

sub set_pkg_namespace {
    my $self = shift;

    my $pkg_ns = $self->{doc}->documentElement()->getAttribute('xmlns');
    $self->{parser}->registerNs( pkg => $pkg_ns );
}

sub set_metadata_namespace {
    my $self = shift;

    my $meta_element = $self->{parser}->findnodes('/pkg:package/pkg:metadata')->[0];
    my $dc_ns = $meta_element->getAttribute('xmlns:dc');
    unless ($dc_ns) {
        $dc_ns = $self->{parser}->findnodes('/pkg:package')->[0]->getAttribute('xmlns:dc');
    }

    $self->{parser}->registerNs( dc => $dc_ns );
}


sub in_manifest { shift->context_node( 'manifest' ) }
sub in_metadata { shift->context_node( 'metadata' ) }
sub in_spine    { shift->context_node( 'spine'    ) }
sub in_guide    { shift->context_node( 'guide'    ) }


1;
