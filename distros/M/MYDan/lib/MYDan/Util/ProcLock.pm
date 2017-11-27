package MYDan::Util::ProcLock;

=head1 NAME

MYDan::Util::ProcLock - Advisory lock using a regular file

=head1 SYNOPSIS

 use MYDan::Util::ProcLock;

 my $lock = MYDan::Util::ProcLock->new( '/lock/file' );

 if ( my $pid = $lock->check() )
 {
     print "Locked by $pid.\n";
 }

 $lock->lock();
 
=cut
use strict;
use warnings;
use Carp;
use File::Spec;
use Fcntl qw( :flock );
use Digest::MD5;

sub new
{
    my ( $class, $file, $match, $self ) = splice @_, 0, 2;

    die "file undef" unless $self->{file} = $file;

    $ENV{mydan_proclock_md5} = $self->{match} = Digest::MD5->new()->add( $file )->hexdigest();;

    my $mode = -f ( $file = File::Spec->rel2abs( $file ) ) ? '+<' : '+>';

    confess "invalid lock file: $file" if -e $file && ! -f $file;
    confess "open $file: $!" unless open $self->{fh}, $mode, $file;

    bless $self, ref $class || $class;
}

=head1 METHODS

=head3 check()

Returns PID of owner, undef if not locked.

=cut
sub check
{
    my $self = shift;
    my ( $file, $fh, $pid ) = $self->{file};
    return open( $fh, '<', $file ) && ( $pid = $self->read( $fh ) )
        ? $pid : undef;
}

=head3 lock()

Attempts to acquire lock. Returns pid if successful, undef otherwise.

=cut
sub lock
{
    local $| = 1;

    my ( $self, $pid ) = shift;
    my $fh = $self->{fh};

    return $pid unless flock $fh, LOCK_EX | LOCK_NB;

    unless ( $pid = $self->read() )
    {
        seek $fh, 0, 0;
        truncate $fh, 0;
        print $fh ( $pid = $$ );
    }
    elsif ( $pid ne $$ )
    {
        $pid = undef;
    }
 
    flock $fh, LOCK_UN;
    return $pid;
}

=head3 read()

Returns a running pid or undef. 

=cut
sub read
{
    my ( $self, $fh, $pid ) = splice @_, 0, 2;
    $pid = seek( ( $fh ||= $self->{fh} ), 0, 0 ) && read( $fh, $pid, 16 )
        && $pid =~ /^(\d+)/ && kill( 0, $1 ) ? $1 : undef;
    
    return $pid unless defined $pid && $self->{match};

    open my $ch, '<', "/proc/$pid/environ" or return undef;
    my $cmdline = <$ch>;
    close $ch;

    return $cmdline =~ /$self->{match}/ ? $pid : undef;
}
 
1;
