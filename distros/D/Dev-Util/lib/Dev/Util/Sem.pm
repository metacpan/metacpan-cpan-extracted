package Dev::Util::Sem;

use Dev::Util::Syntax;
use Dev::Util::File qw(mk_temp_dir dir_writable dir_suffix_slash);
use Exporter        qw(import);

use FileHandle;
use Carp();
use Fcntl 'LOCK_EX';

our $VERSION = version->declare("v2.19.11");

our @EXPORT_OK = qw(
    new
    unlock
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

########################################
#            Methods                   #
########################################

sub new {
    my $class    = shift(@_);
    my $filespec = shift(@_) || Carp::croak("What filespec?");
    my $timeout  = shift     || 60;

    my $lock_dir_parent = _get_locks_dir($filespec);

    local $SIG{ ALRM } = sub { die "Timeout aquiring the lock on $filespec\n" };
    alarm $timeout if ( $timeout > 0 );

    $filespec =~ s{^.*/}{};
    $filespec = $lock_dir_parent . $filespec;

    my $fh = FileHandle->new;
    $fh->open( '>' . $filespec )
        or Carp::croak("Can't open semaphore file $filespec: $!\n");
    chmod 0666, $filespec;    # assuming you want it a+rw

    flock $fh, LOCK_EX;

    alarm 0;
    return bless { file => $filespec, 'fh' => $fh }, ref($class) || $class;
}

sub unlock {
    close( delete $_[0]{ 'fh' } or return 0 );
    unlink( $_[0]{ file } );
    return 1;
}

sub _get_locks_dir {
    my $spec       = shift || undef;
    my @locks_dirs = qw(/var/lock /var/locks /run/lock /tmp);

    my $dirfile_re = qr<^ ( (?: .* / (?: \.\.?\z )? )? ) ([^/]*) >xs;
    my ( $spec_dir, $spec_file );

    # add spec's dir to list of possible lock dirs
    if ( defined $spec && $spec =~ m{/} ) {
        ( $spec_dir, $spec_file ) = ( $spec =~ $dirfile_re );
        unshift @locks_dirs, $spec_dir;
    }

    # find first writable lock dir
    foreach my $locks_dir (@locks_dirs) {
        if ( dir_writable($locks_dir) ) {
            return dir_suffix_slash($locks_dir);
        }
    }
    Carp::croak("Could not find a writable dir to make lock.$!\n");
}

1;

=pod

=encoding utf-8

=head1 NAME

Dev::Util::Sem -  Module to do Semaphore locking

=head1 VERSION

Version v2.19.11

=head1 SYNOPSIS

To ensure that only one instance of a program runs at a time, 
create a semaphore lock file. A second instance will wait until
the first lock is unlocked before it can proceed or it times out.

    use Dev::Util::Sem;

    my $sem = Sem->new('mylock.sem');
    ...
    $sem->unlock;

=head1 EXPORT

    new
    unlock

=head1 METHODS

=head2 B<new>

Initialize semaphore.  You can specify the full path to the lock, 
and if the directory you specify exists and is writable then the 
lock file will be placed there.  If you don't specify a directory
or the one you specified is not writable, then a list of alternate
lock dirs will be tried.

    my $sem1 = Sem->new('/wherever/locks/mylock1.sem');
    my $sem2 = Sem->new('mylock2.sem', TIMEOUT);

C<TIMEOUT> number of seconds to wait while trying to acquire a lock. Default = 60 seconds

Alternate lock dirs: 

    qw(/var/lock /var/locks /run/lock /tmp);

=head2 B<unlock>

Unlock semaphore and delete lock file.

    $sem->unlock;

=head1 AUTHOR

Matt Martini, C<< <matt at imaginarywave.com> >>

=head1 BUGS

C<flock> may not work over C<nfs>.

Please report any bugs or feature requests to C<bug-dev-util at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dev::Util::Backup

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util>

=item * Search CPAN

L<https://metacpan.org/release/Dev-Util>

=back

=head1 ACKNOWLEDGMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright © 2001-2025 by Matt Martini.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007

=cut

__END__
