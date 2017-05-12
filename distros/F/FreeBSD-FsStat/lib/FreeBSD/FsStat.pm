package FreeBSD::FsStat;
$FreeBSD::FsStat::VERSION = '0.107';
use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;

use FreeBSD::FileSystem;

@ISA = qw(Exporter DynaLoader);

bootstrap FreeBSD::FsStat;

1;

# ABSTRACT:  Query a FreeBSD system for the list of mounted filesystems

=head1 NAME

FreeBSD::FsStat - Get mounted filesystems in FreeBSD

=head1 VERSION

version 0.107

=head1 SYNOPSIS

 my $mounts = FreeBSD::FsStat::getfsstat;

=head1 DESCRIPTION

Query a FreeBSD system for the list of mounted filesystems.

=head1 METHODS

=over 2

=item get_filesystems

Returns a list of L<FreeBSD::FileSystem> objects, corresponding
to the filesystems of the host.

=cut

sub get_filesystems {
	map { FreeBSD::FileSystem->new( $_ ) } @{ &getfsstat() }
}

=item getfsstat

Returns an arrayref of hashrefs. Each hashref represents a filesystem and its keys
are the attributes of that filesystem. For the list of keys, have a look at the
statfs(2) man page. For convenience, here is the relevant struct as of this
writing:

 struct statfs {
 uint32_t f_version;             /* structure version number */
 uint32_t f_type;                /* type of filesystem */
 uint64_t f_flags;               /* copy of mount exported flags */
 uint64_t f_bsize;               /* filesystem fragment size */
 uint64_t f_iosize;              /* optimal transfer block size */
 uint64_t f_blocks;              /* total data blocks in filesystem */
 uint64_t f_bfree;               /* free blocks in filesystem */
 int64_t  f_bavail;              /* free blocks avail to non-superuser */
 uint64_t f_files;               /* total file nodes in filesystem */
 int64_t  f_ffree;               /* free nodes avail to non-superuser */
 uint64_t f_syncwrites;          /* count of sync writes since mount */
 uint64_t f_asyncwrites;         /* count of async writes since mount */
 uint64_t f_syncreads;           /* count of sync reads since mount */
 uint64_t f_asyncreads;          /* count of async reads since mount */
 uint64_t f_spare[10];           /* unused spare */
 uint32_t f_namemax;             /* maximum filename length */
 uid_t     f_owner;              /* user that mounted the filesystem */
 fsid_t    f_fsid;               /* filesystem id */
 char      f_charspare[80];          /* spare string space */
 char      f_fstypename[MFSNAMELEN]; /* filesystem type name */
 char      f_mntfromname[MNAMELEN];  /* mounted filesystem */
 char      f_mntonname[MNAMELEN];    /* directory on which mounted */
 };

B<Note, the f_fsid doesn't seem to work at present.>

=back

=head1 AUTHOR

Athanasios Douitsis C<< <aduitsis@cpan.org> >>

=head1 SUPPORT

Please open a ticket at L<https://github.com/aduitsis/perl-FreeBSD-FsStat>.

=head1 COPYRIGHT & LICENSE

Copyright 2016 Athanasios Douitsis, all rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
