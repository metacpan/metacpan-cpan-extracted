package MColPro::Util::Logger;

=head1 NAME

 MColPro::Util::Logger - logger

=cut

use strict;
use warnings;

use Carp;
use POSIX;
use Thread::Semaphore;

our $HANDLE = \*STDERR;

sub new
{
    my ( $class, $handle ) = splice @_;
    confess 'cannot write to handle' unless -w ( $handle ||= $HANDLE );
    bless { handle => $handle, mutex => Thread::Semaphore->new() },
        ref $class || $class;
}

sub say
{
    my $self = shift;
    my $handle = $self->{handle};
    if ( @_ )
    {
        $self->{mutex}->down();
        syswrite $handle, POSIX::sprintf( @_ ) . "\n";
        $self->{mutex}->up();
    }
    return $self;
}

1;
