package MyBuild;

use strict;
use warnings;

use base qw/ Module::Build /;

sub new {
    my ( $self, %args ) = @_;

    return $self->SUPER::new( 
        c_source => [ qw/ houdini / ],
        %args 
    );
}


1;
