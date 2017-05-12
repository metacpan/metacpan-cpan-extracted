# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Userland::Find;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Module ();
use Filesys::POSIX::Path   ();

use Errno;

my @METHODS = qw(find);

Filesys::POSIX::Module->export_methods( __PACKAGE__, @METHODS );

=head1 NAME

Filesys::POSIX::Userland::Find - Crawl directories in a filesystem

=head1 SYNOPSIS

    use Filesys::POSIX;
    use Filesys::POSIX::Real;
    use Filesys::POSIX::Userland::Find;

    my $fs = Filesys::POSIX->new(Filesys::POSIX::Real->new,
        'special'   => 'real:/home/foo',
        'noatime'   => 1
    );

    $fs->find(sub {
        my ($path, $inode) = @_;
        printf("0%o %s\n", $inode->{'mode'}, $path->full);
    }, '/');

=head1 DESCRIPTION

This module provides an extension module to L<Filesys::POSIX> that operates
very similarly in principle to the Perl Core module L<File::Find>, albeit with
some minor differences and fewer options.  For the sake of efficiency, tail
recursion, rather than pure call recursion, is used to handle very deep
hierarchies.

=head1 USAGE

=over

=item C<$fs-E<gt>find($callback, @paths)>

=item C<$fs-E<gt>find($callback, $options, @paths)>

C<$fs-E<gt>find> will perform recursive descent into each path passed, printing
the full pathname of each item found relative to each item found in the
C<@paths> list.  For each item found, both a Filesys::POSIX::Path object, and an
inode, respectively, are passed as the sole arguments to the callback.  With
this mechanism, it is possible to retrieve path data from each item in every way
currently provided by L<File::Find>, without retaining global state to do so.
As a reference to the corresponding item's inode object is passed, there is no
need to perform a C<$fs-E<gt>stat> call to further inspect the item.

When called with an C<$options> argument, specified in the form of an anonymous
HASH, the following flags (whose values are set nonzero) are honored:

=over

=item C<follow>

Any symlinks found along the way are resolved; if the paths they resolve to are
those of directories, then further descent will be made into said directories.

=item C<recursion_mode>

Specifies the strategy to use when recursing through directories. Available
options are:

=over

=item breadth

Traverse in a breadth-first manner. This is the default mode.

=item depth

Traverse in a depth-first manner.

=item device

Traverse inodes that are on the same device first. This mode also tracks the
current filesystem it is processing and invokes the C<$fs-E<gt>enter_filesystem>
and C<$fs-E<gt>exit_filesystem> methods when the current filesystem changes to
optimize these calls.

=back

=item C<ignore_missing>

When set, ignore if a file or directory becomes missing during recursion. If the
value is a coderef, calls that function with the name of the missing file.

=item C<ignore_inaccessible>

When set, ignore if a file or directory becomes unreadable during recursion. If
the value is a coderef, calls that function with the name of the inaccessible file.

=cut

sub find {
    my $self     = shift;
    my $callback = shift;
    my %opts     = ref $_[0] eq 'HASH' ? %{ (shift) } : ();
    my @args     = @_;

    my @paths = map { Filesys::POSIX::Path->new($_) } @args;
    my @inodes = map { $opts{'follow'} ? $self->stat($_) : $self->lstat($_) } @args;

    my $recursion_mode = defined $opts{'recursion_mode'} ? $opts{'recursion_mode'} : 'breadth';
    if ( $recursion_mode ne 'breadth' && $recursion_mode ne 'depth' && $recursion_mode ne 'device' ) {
        die "Invalid recursion mode $recursion_mode specified";
    }

    my $current_dev;

    while ( my $inode = pop @inodes ) {
        my $path = pop @paths;

        if ( $recursion_mode eq 'device' && ( !defined $current_dev || $current_dev != $inode->{'dev'} ) ) {
            if ( defined $current_dev && $current_dev->can('exit_filesystem') ) {
                $current_dev->exit_filesystem();
            }
            if ( defined $inode->{'dev'} && $inode->{'dev'}->can('enter_filesystem') ) {
                $inode->{'dev'}->enter_filesystem();
            }
            $current_dev = $inode->{'dev'};
        }

        $callback->( $path, $inode );

        if ( $inode->dir ) {
            my $directory;
            eval { $directory = $inode->directory->open; };
            if ($@) {
                if ( $! == &Errno::ENOENT && $opts{'ignore_missing'} ) {
                    $opts{'ignore_missing'}->( $path->full() )
                      if ref $opts{'ignore_missing'} eq 'CODE';
                }
                elsif ( $! == &Errno::EACCES && $opts{'ignore_inaccessible'} ) {
                    $opts{'ignore_inaccessible'}->( $path->full() )
                      if ref $opts{'ignore_inaccessible'} eq 'CODE';
                }
                else {
                    die $@;
                }
            }

            if ( defined $directory ) {
                while ( defined( my $item = $directory->read ) ) {
                    next if $item eq '.' || $item eq '..';
                    my $subpath = Filesys::POSIX::Path->new( $path->full . "/$item" );
                    my $subnode = $self->{'vfs'}->vnode( $directory->get($item) );

                    if ( $opts{'follow'} && defined $subnode && $subnode->link ) {
                        $subnode = $self->stat( $subnode->readlink );
                    }

                    if ( !defined $subnode ) {
                        if ( $opts{'ignore_inaccessible'} ) {
                            $opts{'ignore_inaccessible'}->( $path->full() . "/$item" )
                              if ref $opts{'ignore_inaccessible'} eq 'CODE';
                        }
                        else {
                            die "Failed to read " . $path->full() . "/$item";
                        }
                    }
                    elsif ( $recursion_mode eq 'depth' || ( $recursion_mode eq 'device' && $current_dev == $subnode->{'dev'} ) ) {
                        push @paths,  $subpath;
                        push @inodes, $subnode;
                    }
                    else {
                        unshift @paths,  $subpath;
                        unshift @inodes, $subnode;
                    }
                }
                $directory->close;
            }
        }
    }
}

1;

__END__

=head1 AUTHOR

Written by Xan Tronix <xan@cpan.org>

=head1 CONTRIBUTORS

=over

=item Rikus Goodell <rikus.goodell@cpanel.net>

=item Brian Carlson <brian.carlson@cpanel.net>

=item John Lightsey <jd@cpanel.net>

=back

=head1 COPYRIGHT

Copyright (c) 2014, cPanel, Inc.  Distributed under the terms of the Perl
Artistic license.
