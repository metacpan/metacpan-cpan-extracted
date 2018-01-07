package Mail::AuthenticationResults::Token;
require 5.010;
use strict;
use warnings;
our $VERSION = '1.20171230'; # VERSION
use Carp;

sub new {
    my ( $class, $header ) = @_;

    my $self = {};
    bless $self, $class;

    $self->{ 'header' } = $header;
    $self->parse();

    return $self;
}

sub value {
    my ( $self ) = @_;
    return $self->{ 'value' };
}

sub remainder {
    my ( $self ) = @_;
    return $self->{ 'header' };
}

sub parse {
    my ( $self ) = @_;
    croak 'parse not implemented';
}

1;;

