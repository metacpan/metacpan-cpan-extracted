package Mail::AuthenticationResults::Token::Separator;
require 5.010;
use strict;
use warnings;
our $VERSION = '1.20171230'; # VERSION
use Carp;

use base 'Mail::AuthenticationResults::Token';

sub is {
    my ( $self ) = @_;
    return 'separator';
}

sub parse {
    my ($self) = @_;

    my $header = $self->{ 'header' };
    my $value = q{};

    my $first = substr( $header,0,1 );
    croak 'not a separator' if $first ne ';';

    $header   = substr( $header,1 );

    $self->{ 'value' } = ';';
    $self->{ 'header' } = $header;

    return;
}

1;

