package KinoSearch1::Store::FSLock;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Store::Lock );

BEGIN { __PACKAGE__->init_instance_vars() }

use Fcntl qw( :DEFAULT :flock );
use File::Spec::Functions qw( catfile );
use KinoSearch1::Store::FSInvIndex;

my $disable_locks = 0;    # placeholder -- locks always enabled for now

sub init_instance {
    my $self = shift;

    # derive the lockfile's filepath
    $self->{lock_name} = catfile(
        $KinoSearch1::Store::FSInvIndex::LOCK_DIR, # TODO fix this stupid hack
        $self->{invindex}->get_lock_prefix . "-$self->{lock_name}"
    );
}

sub do_obtain {
    my $self = shift;

    return 1 if $disable_locks;

    my $lock_name = $self->{lock_name};

    # check for locks created by old processes and remove them
    if ( -e $lock_name ) {
        open( my $fh, $lock_name ) or confess "Can't open $lock_name: $!";
        my $line = <$fh>;
        $line =~ /pid: (\d+)/;
        my $pid = $1;
        close $fh or confess "Can't close '$lock_name': $!";
        unless ( kill 0 => $pid ) {
            warn "Lockfile looks dead - removing";
            unlink $lock_name or confess "Can't unlink '$lock_name: $!";
        }
    }

    # create a lock by creating a lockfile
    return
        unless sysopen( my $fh, $lock_name, O_CREAT | O_WRONLY | O_EXCL );

    # print pid and path to the lock file, using YAML for future compat
    print $fh "pid: $$\ninvindex: " . $self->{invindex}->get_path . "\n";
    close $fh or confess "Can't close '$lock_name': $!";

    # success!
    return 1;
}

sub release {
    my $self = shift;

    return if $disable_locks;

    # release the lock by removing the lockfile from the file system
    unlink $self->{lock_name}
        or confess("Couldn't unlink file '$self->{lock_name}': $!");
}

sub is_locked {
    # if the lockfile exists, the resource is locked
    return ( -e $_[0]->{lock_name} or $disable_locks );
}

1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Store::FSLock - lock an FSInvIndex

==head1 DESCRIPTION

File-system-based implementation of
L<KinoSearch1::Store::Lock|KinoSearch1::Store::Lock>.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
