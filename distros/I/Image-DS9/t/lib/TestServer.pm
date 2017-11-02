package t::TestServer;

use strict;
use warnings;

use parent 'Image::DS9';

sub new {

    my $class   = shift;
    my $verbose = shift;

    # some facilities (e.g. print) will only work if
    # XPA_METHOD=local
    $ENV{XPA_METHOD} = 'local';

    my $self
      = $class->SUPER::new( { Server => 'ImageDS9', verbose => $verbose } );

    unless ( $self->nservers ) {

        my $pid = fork;
        die( "unable to fork: $!\n" ) if ! defined $pid;
        if ( $pid ) {
                $self->{_child_pid} = $pid;
                $self->wait() or die( "unable to connect to DS9\n" );
            }
        else {
            exec( qw[ds9 -title ImageDS9] );
        }
    }

    return $self;
}

sub DESTROY {

    my $self = shift;

    if ( $self->{_child_pid} ) {
        $self->quit ;
        waitpid $self->{_child_pid}, 0;
    }

    $self->SUPER::DESTROY;
}

1;
