package KinoSearch1::Store::FSInvIndex;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Store::InvIndex );

our $LOCK_DIR;    # used by FSLock

use File::Spec::Functions qw( canonpath catfile catdir tmpdir no_upwards );
use Fcntl;

BEGIN {
    __PACKAGE__->init_instance_vars();

    # confirm or create a directory to put lockfiles in
    $LOCK_DIR = catdir( tmpdir, 'kinosearch_lockdir' );
    if ( !-d $LOCK_DIR ) {
        mkdir $LOCK_DIR or die "couldn't mkdir '$LOCK_DIR': $!";
        chmod 0777, $LOCK_DIR;
    }
}

use Digest::MD5 qw( md5_hex );
use KinoSearch1::Store::InStream;
use KinoSearch1::Store::OutStream;
use KinoSearch1::Store::FSLock;
use KinoSearch1::Index::IndexFileNames;

sub init_instance {
    my $self = shift;

    # clean up path.
    my $path = $self->{path} = canonpath( $self->{path} );

    if ( $self->{create} ) {
        # clear out lockfiles related to this path
        my $lock_prefix = $self->get_lock_prefix;
        opendir( my $lock_dh, $LOCK_DIR )
            or confess("Couldn't opendir '$LOCK_DIR': $!");
        my @lockfiles = grep {/$lock_prefix/} readdir $lock_dh;
        closedir $lock_dh
            or confess("Couldn't closedir '$LOCK_DIR': $!");
        for (@lockfiles) {
            $_ = catfile( $LOCK_DIR, $_ );
            unlink $_ or confess("couldn't unlink '$_': $!");
        }

        # blast any existing index files
        if ( -e $path ) {
            opendir( my $invindex_dh, $path )
                or confess("Couldn't opendir '$path': $!");
            my @to_remove;
            for ( readdir $invindex_dh ) {
                if (/(^\w+\.(?:cfs|del)$)/) {
                    push @to_remove, $1;
                }
                elsif ( $_ eq 'segments' ) {
                    push @to_remove, 'segments';
                }
                elsif ( $_ eq 'delqueue' ) {
                    push @to_remove, 'delqueue';
                }
            }
            for my $removable (@to_remove) {
                $removable = catfile( $path, $removable );
                unlink $removable
                    or confess "Couldn't unlink file '$removable': $!";
            }
            closedir $invindex_dh
                or confess("Couldn't closedir '$path': $!");
        }
        if ( !-d $path ) {
            mkdir $path or confess("Couldn't mkdir '$path': $!");
        }
    }

    # by now, we should have a directory, so throw an error if we don't
    if ( !-d $path ) {
        confess("Can't open invindex location '$path': $! ")
            unless -e $path;
        confess("invindex location '$path' isn't a directory");
    }
}

sub open_outstream {
    my ( $self, $filename ) = @_;
    my $filepath = catfile( $self->{path}, $filename );
    sysopen( my $fh, $filepath, O_CREAT | O_RDWR | O_EXCL )
        or confess("Couldn't open file '$filepath': $!");
    binmode($fh);
    return KinoSearch1::Store::OutStream->new($fh);
}

sub open_instream {
    my ( $self, $filename, $offset, $len ) = @_;
    my $filepath = catfile( $self->{path}, $filename );
    # must be unbuffered, or PerlIO messes up with the shared handles
    open( my $fh, "<:unix", $filepath )
        or confess("Couldn't open file '$filepath': $!");
    binmode($fh);
    return KinoSearch1::Store::InStream->new( $fh, $offset, $len );
}

sub list {
    my $self = shift;
    opendir( my $dh, $self->{path} )
        or confess("Couldn't opendir '$self->{path}'");
    my @files = no_upwards( readdir $dh );
    closedir $dh or confess("Couldn't closedir '$self->{path}'");
    return @files;
}

sub file_exists {
    my ( $self, $filename ) = @_;
    return -e catfile( $self->{path}, $filename );
}

sub rename_file {
    my ( $self, $from, $to ) = @_;
    $_ = catfile( $self->{path}, $_ ) for ( $from, $to );
    rename( $from, $to )
        or confess("couldn't rename file '$from' to '$to': $!");
}

sub delete_file {
    my ( $self, $filename ) = @_;
    $filename = catfile( $self->{path}, $filename );
    unlink $filename or confess("couldn't unlink file '$filename': $!");
}

sub slurp_file {
    my ( $self, $filename ) = @_;
    my $filepath = catfile( $self->{path}, $filename );
    open( my $fh, "<", $filepath )
        or confess("Couldn't open file '$filepath': $!");
    binmode($fh);
    local $/;
    return <$fh>;
}

sub make_lock {
    my $self = shift;
    return KinoSearch1::Store::FSLock->new( @_, invindex => $self );
}

# Create a hashed string derived from this invindex's path.
sub get_lock_prefix {
    my $self = shift;
    return "kinosearch-" . md5_hex( canonpath( $self->{path} ) );
}

sub close { }

1;

__END__

=head1 NAME

KinoSearch1::Store::FSInvIndex - file system InvIndex 

=head1 SYNOPSIS

    my $invindex = KinoSearch1::Store::FSInvIndex->new(
        path   => '/path/to/invindex',
        create => 1,
    );

=head1 DESCRIPTION

Implementation of KinoSearch1::Store::InvIndex using a single file system 
directory and multiple files.

=head1 CONSTRUCTOR

=head2 new

C<new> takes two parameters:

=over 

=item

B<path> - the location of the invindex.

=item

B<create> - if set to 1, create a fresh invindex, clobbering an
existing one if necessary. Default value is 0, indicating that an existing
invindex should be opened.

=back

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut
