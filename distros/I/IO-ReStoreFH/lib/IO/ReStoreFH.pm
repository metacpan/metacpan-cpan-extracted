package IO::ReStoreFH;

# ABSTRACT: store/restore file handles

use 5.10.0;

use strict;
use warnings;

our $VERSION = '0.10';

# In Perl 5.10.1 a use or require of FileHandle or something in the
# FileHandle hierarchy (like FileHandle::Fmode, below) will cause the
# compiler to creat a stash for FileHandle.  Then, there's some
# code in Perl_newio which checks if FileHandle has been loaded (just
# by checking for the stash) and aliases it to IO::Handle.
#
#  This it mucks up method calls on filehandles if FileHandle isn't
#  actually loaded, resulting in errors such as
#
#   Can't locate object method "getline" via package "FileHandle"
#
# see http://perlmonks.org/?node_id=1073753, and tobyink's reply

# So, we explicitly load FileHandle on 5.10.x to avoid these action
# at a distance problems.
use if $^V ge v5.10.0 && $^V lt v5.11.0, 'FileHandle';

use FileHandle::Fmode ();
use POSIX             ();
use IO::Handle;
use Scalar::Util;
use Try::Tiny ();

sub _croak {
    require Carp;
    goto &Carp::croak;
}

sub new {
    my $class = shift;

    my $obj = bless { dups => [] }, $class;
    $obj->store( $_ ) for @_;
    return $obj;
}

sub store {
    my ( $self, $fh ) = @_;

    # if $fh is a reference, or a GLOB, it's probably
    # a filehandle object of somesort

    if ( ref( $fh ) || 'GLOB' eq ref( \$fh ) ) {

        # now that we are sure that everything is loaded,
        # check if it is an open filehandle; this doesn't disambiguate
        # between objects that aren't filehandles or closed filehandles.
        _croak( "\$fh is not an open filehandle\n" )
          unless FileHandle::Fmode::is_FH( $fh );

        # get access mode; open documentation says mode must
        # match that of original filehandle; do the best we can
        my $mode
          = FileHandle::Fmode::is_RO( $fh ) ? '<'
          : FileHandle::Fmode::is_WO( $fh ) ? '>'
          : FileHandle::Fmode::is_W( $fh )
          && FileHandle::Fmode::is_R( $fh ) ? '+<'
          : undef;

        # give up
        _croak( "inexplicable error: unable to determine mode for \$fh;\n" )
          if !defined $mode;

        $mode .= '>' if FileHandle::Fmode::is_A( $fh );

        # dup the filehandle
        open my $dup, $mode . '&', $fh
          or _croak( "error fdopening \$fh: $!\n" );

        push @{ $self->{dups} }, { fh => $fh, mode => $mode, dup => $dup };
    }

    elsif (Scalar::Util::looks_like_number( $fh )
        && POSIX::ceil( $fh ) == POSIX::floor( $fh ) )
    {

        # as the caller specifically used an fd, don't go through Perl's
        # IO system
        my $dup = POSIX::dup( $fh )
          or _croak( "error dup'ing file descriptor $fh: $!\n" );

        push @{ $self->{dups} }, { fd => $fh, dup => $dup };
    }

    else {
        _croak(
            "\$fh must be opened Perl filehandle or object or integer file descriptor\n"
        );
    }

    return;
}

sub restore {
    my $self = shift;

    my $dups = $self->{dups};
    ## no critic (ProhibitAccessOfPrivateData)
    while ( my $dup = pop @{$dups} ) {

        if ( exists $dup->{fd} ) {
            POSIX::dup2( $dup->{dup}, $dup->{fd} )
              or _croak( "error restoring file descriptor $dup->{fd}: $!\n" );
            POSIX::close( $dup->{dup} );
        }

        else {
            open( $dup->{fh}, $dup->{mode} . '&', $dup->{dup} )
              or _croak( "error restoring file handle $dup->{fh}: $!\n" );
            close( $dup->{dup} );
        }
    }
    return;
}

sub DESTROY {
    my $self = shift;
    Try::Tiny::try { $self->restore }
    Try::Tiny::catch { _croak $_ };
    return;
}

1;

#
# This file is part of IO-ReStoreFH
#
# This software is Copyright (c) 2012 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

IO::ReStoreFH - store/restore file handles

=head1 VERSION

version 0.10

=head1 SYNOPSIS

        use IO::ReStoreFH;

        {
           my $fhstore = IO::ReStoreFH->new( *STDOUT );

           open( STDOUT, '>', 'file' );
        } # STDOUT will be restored when $fhstore is destroyed

        # or, one at-a-time
        {
           my $fhstore = IO::ReStoreFH->new;
           $store->store( *STDOUT );
           $store->store( $myfh );

           open( STDOUT, '>', 'file' );
           open( $myfh, '>', 'another file' );
        } # STDOUT and $myfh will be restored when $fhstore is destroyed

=head1 DESCRIPTION

Redirecting and restoring I/O streams is straightforward but a chore,
and can lead to strangely silent errors if you forget to restore
STDOUT or STDERR.

B<IO::ReStoreFH> helps keep track of the present state of filehandles and
low-level file descriptors and restores them either explicitly or when
the B<IO::ReStoreFH> object goes out of scope.

It uses the standard Perl filehandle duplication methods (via B<open>)
for filehandles, and uses B<POSIX::dup> and B<POSIX::dup2> for file
descriptors.

File handles and descriptors are restored in the reverse order that
they are stored.

=head1 INTERFACE

=over

=item new

        my $fhstore = IO::ReStoreFH->new;
        my $fhstore = IO::ReStoreFH->new( $fh1, $fh2, $fd, ... );

Create a new object and an optional list of Perl filehandles or
integer file descriptors.

The passed handles and descriptors will be duplicated to be restored
when the object is destroyed or the B<restore> method is called.

=item store

        $fhstore->store( $fh );

        $fhstore->store( $fd );

The passed handles and descriptors will be duplicated to be restored
when the object is destroyed or the B<restore> method is called.

=item restore

   $fhstore->restore;

Restore the stored file handles and descriptors, in the reverse order
that they were stored.  This is automatically called when the object
is destroyed.

=back

=head1 DIAGNOSTICS

=over

=item C<< $fh is not an open filehandle >>

The passed filehandle failed a check to ensure that it was an open
filehandle.  Make sure it's a) a real filehandle; b) it's open.

=item C<< inexplicable error: unable to determine mode for $fh >>

B<IO::ReStoreFH> was unable to get the access mode for the passed file
handle.  Are you sure that it's really a filehandle object?

=item C<< error fdopening %s: %s >>

Perl B<open()> was unable to duplicate the passed filehandle for the
specified reason.

=item C<< error dup'ing file descriptor %s: %s >>

B<POSIX::dup()> was unable to duplicate the passed file descriptor for the
specified reason.

=item C<< $fh must be opened Perl filehandle or object or integer file descriptor >>

The passed C<$fh> argument wasn't recognized as a Perl filehandle or a
file descriptor.  Please try again.

=item C<< error restoring file descriptor %d: %s >>

Attempting to restore the file descriptor failed for the specified reason.

=item C<< error restoring file handle %s: %s >>

Attempting to restore the Perl file handle failed for the specified reason.

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-io-restorefh@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=IO-ReStoreFH

=head2 Source

Source is available at

  https://gitlab.com/djerius/io-restorefh

and may be cloned from

  https://gitlab.com/djerius/io-restorefh.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
