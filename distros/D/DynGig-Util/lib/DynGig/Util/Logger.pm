=head1 NAME

DynGig::Util::Logger - Thread-safe logging

=cut
package DynGig::Util::Logger;

use warnings;
use strict;
use Carp;

use threads;
use Thread::Semaphore;

use POSIX;
use Cwd qw();

$| ++;

=head1 SYNOPSIS

 use DynGig::Util::Logger;
 
 my $time = 'utc' if open my $handle, '>>', '/some/path';

 my $logger = DynGig::Util::Logger->new
 (
     log => $handle, ## path or I/O handle, *STDOUT if undef
     time => $time,  ## 'raw', 'utc', 'local', omit timestamp if undef
 );

 $logger->write( "timestamp in %s", $time );

=cut
sub new
{
    my ( $class, %param ) = @_;
    my $log = $param{log};
    my %this = ( time => $param{time}, mutex => Thread::Semaphore->new() );

    if ( ! defined $log )
    {
        $this{handle} = *STDOUT;
    }
    elsif ( fileno $log )
    {
        croak 'inaccessable log' unless -w ( $this{handle} = $log );
    }
    else
    {
        croak 'invalid log path'
            unless defined ( $log = Cwd::abs_path( $log ) )
                && ( ! -e $log || -f $log );

        croak "open $log: $!" unless open $this{handle}, '>>', $log;
    }

    bless \%this, ref $class || $class;
}

=head1 METHODS

=head2 write

See printf().

=cut
sub write
{
    return if @_ == 1;

    my $this = shift @_;
    my $handle = $this->{handle};

    $this->{mutex}->down();

    if ( my $mode = $this->{time} )
    {
        $mode = lc $mode;

        my $time = $mode eq 'raw' ? time : $mode eq 'local'
            ? POSIX::strftime( '%Y%m%d_%H%M%S', localtime ) 
            : POSIX::strftime( '%Y%m%d_%H%M%S', gmtime );

        syswrite $handle, sprintf "%s %s\n", $time, POSIX::sprintf @_;
    }
    else
    {
        syswrite $handle, sprintf "%s\n", POSIX::sprintf @_;
    }

    $this->{mutex}->up();
}

=head1 SEE ALSO

threads, Thread::Semaphore

=head1 NOTE

See DynGig::Util

=cut

1;

__END__
