package MColPro::Util::PID;

=head1 NAME

 MColPro::Util::PID - lock file for record pid

=cut

use warnings;
use strict;
use Carp;

use Cwd qw();
use Fcntl qw( :flock );

sub new
{
    my ( $class, $file ) = @_;

    croak 'invalid/undefined lock file' unless $file
        && defined ( $file = Cwd::abs_path( $file ) )
        && ( ! -e $file || -f $file );

    my $mode = -f $file ? '+<' : '+>';
    my $this;

    croak "open $file: $!" unless open $this, $mode, $file;

    bless \$this, ref $class || $class;
}

sub lock
{
    my $this = shift @_;
    my $handle = $$this;
    my $pid;

    return $pid unless flock $handle, LOCK_EX | LOCK_NB;

    sysseek $handle, 0, 0;
    sysread $handle, $pid, 64;

    if ( $pid && $pid eq $$ )
    {
    }
    elsif ( $pid && $pid =~ /^\d+$/ && kill 0, $pid )
    {
        $pid = undef;
    }
    else
    {
        sysseek $handle, 0, 0;
        truncate $handle, 0;
        syswrite $handle, ( $pid = $$ );
    }
 
    flock $handle, LOCK_UN;
    return $pid;
}

sub check
{
    my ( $class, $file ) = @_;

    croak 'lock file not defined' unless defined $file;

    my ( $handle, $pid );

    return open( $handle, '<', $file ) && read( $handle, $pid, 1024 )
        && $pid =~ /^\d+$/ && $pid && kill( 0, $pid ) ? $pid : 0;
}

1;

__END__
