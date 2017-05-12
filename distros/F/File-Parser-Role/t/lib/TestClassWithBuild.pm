package TestClassWithBuild;

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

sub BUILD {
    my $self = shift;
    print $self->filename, "\n";
}

with "File::Parser::Role";

1;
