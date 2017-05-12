package TestClass;

use strict;
use warnings;

use Moo;

has blob => ( is => "rw" );

sub parse {

    my $self = shift;
    local $/;
    my $fh = $self->fh;

    $self->blob( <$fh> );

}

with "File::Parser::Role";

1;
