package MYDan::Util::Say;

=head1 NAME

MYDan::Util::Say - thread safe logger

=head1 SYNOPSIS

 use MYDan::Util::Say;

 my $log = MYDan::Util::Say->new( $handle );

 $log->say( 'foo', 'bar' );

=cut
use strict;
use warnings;

use Carp;
use POSIX;
use Thread::Semaphore;

=head1 HANDLE

Must be a writable handle. Defaults to STDERR.

=cut
our $HANDLE = \*STDERR;

sub new
{
    my ( $class, $handle ) = splice @_;
    bless { handle => $handle || $HANDLE, mutex => Thread::Semaphore->new() },
        ref $class || $class;
}

=head1 METHODS

=head3 say( @list )

I<say> @list to log. Returns invoking object.

=cut
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
