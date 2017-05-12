# -*-perl-*-
# Creation date: 2003-03-09 15:38:36
# Authors: Don
# Change log:
# $Id: Backup.pm,v 1.33 2007/12/14 03:37:30 don Exp $
#
# Copyright (c) 2003-2007 Don Owens.  All rights reserved.
#
# This is free software; you can redistribute it and/or modify it under
# the Perl Artistic license.  You should have received a copy of the
# Artistic license with this distribution, in the file named
# "Artistic".  You may also obtain a copy from
# http://regexguy.com/license/Artistic
#
# This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.

=pod

=head1 NAME

File::Rotate::Backup - Make backups of multiple directories and
rotate them on unix.

=head1 SYNOPSIS

    my $params = { archive_copies => 2,
                   dir_copies => 1,
                   backup_dir => '/backups',
                   file_prefix => 'backup_'
                   secondary_backup_dir => '/backups2',
                   secondary_archive_copies => 2,
                   verbose => 1,
                   use_flock => 1,
                 };

    my $backup = File::Rotate::Backup->new($params);

    $backup->backup([ [ '/etc/httpd/conf' => 'httpd_conf' ],
                      [ '/var/named' => 'named' ],
                    ]);

    $backup->rotate;

=head1 DESCRIPTION

This module will make backups and rotate them according to your
specification.  It creates a backup directory based on the
file_prefix you specify and the current time.  It then copies the
directories you specified in the call to new() to that backup
directory.  Then a tar'd and compressed file is created from that
directory.  By default, bzip2 is used for compression.

This module has only been tested on Linux and Solaris.

The only external programs used are tar and a compression
program.  Copies and deletes are implemented internally.

=head1 METHODS

=cut

use strict;
use File::Find ();
# use File::Copy ();

{   package File::Rotate::Backup;

    use vars qw($VERSION);

    BEGIN {
        $VERSION = '0.13'; # update below in POD as well
    }

    use File::Rotate::Backup::Copy;

=pod

=head2 new(\%params)

    my $params = { archive_copies => 2,
                   dir_copies => 1,
                   backup_dir => '/backups',
                   file_prefix => 'backup_'
                   secondary_backup_dir => '/backups2',
                   secondary_archive_copies => 2,
                   verbose => 1,
                   use_flock => 1,
                   dir_regex => '\d+-\d+-\d+_\d+_\d+_\d+',
                   file_regex => '\d+-\d+-\d+_\d+_\d+_\d+',
                 };

    my $backup = File::Rotate::Backup->new($params);

Creates a backup object.

=over 4

=item archive_copies

The number of old archive files to keep.

=item no_archive

If set to true, then no compressed archive(s) will be created 
even if archive_copies is set.

=item dir_copies

The number of old backup directories to keep.

=item backup_dir

Where backups are placed.

=item file_prefix

The prefix to use for the backup directories and archive files.
When the directories and archive files are created, the name for
each is created by appending a timestamp to the end of the file
prefix you specify.

=item secondary_backup_dir

Overflow directory to copy files to before deleting them from the
backup directory when rotating.

=item secondary_archive_copies

The number of archive files to keep in the secondary backup
directory.

=item verbose

If set to a true value, status messages will be printed as the
files are being processed.

=item use_flock

If set to a true value, an attempt will be made to acquire a
write lock on any file to be removed during rotation.  If a lock
cannot be acquired, the file will not be removed.  This is useful
for concurrency control, e.g., when your backup script gets run
at the same time as another script that is writing the backups to
tape.

=item use_rm

If set to a true value, the external program /bin/rm will be used
to remove a file in the case where unlink() fails.  This may
occur on systems where the file being removed is larger than 2GB
and such files are not fully supported.

=item dir_regex

Regular expression used to search for directories to rotate.  The
file_prefix is prepended to this to create the final regular
expression.  This is useful for rotating directories that were
not created by this module.

=item file_regex

Regular expression used to search for archive files to rotate.
The file_prefix is prepended to this to create the final regular
expression.  This is useful for rotating files that were not
created by this module.

=back

=cut

#     BEGIN {
#         use vars '%Config';
#         eval 'use Config';
#     }

    sub new {
        my ($proto, $params) = @_;

        my $self = {};
        bless $self, ref($proto) || $proto;
        
        $self->setArchiveCopies(defined($$params{archive_copies}) ? $$params{archive_copies} : 1);
        $self->setDirCopies(defined($$params{dir_copies}) ? $$params{dir_copies} : 1);
        my $dir = $$params{backup_dir};
        $dir = '/tmp' if $dir eq '';
        $self->setBackupDir($dir);
        $self->setSecondaryBackupDir($$params{secondary_backup_dir});
        $self->setSecondaryArchiveCopies($$params{secondary_archive_copies});
        $self->setFilePrefix($$params{file_prefix});
        $self->_setVerbose($$params{verbose});
        $self->_setUseFileLock($$params{use_flock});
        $self->_setUseRm($$params{use_rm});
        $self->{_archive_dir_regex} = $params->{dir_regex} if defined $params->{dir_regex};
        $self->{_archive_file_regex} = $params->{file_regex} if defined $params->{file_regex};
        $self->{_no_archive} = defined $params->{no_archive} ? $params->{no_archive} : 0;

#         foreach my $exe ('tar', 'gzip', 'bzip2', 'rm', 'mv') {
#             if (defined($Config{$exe}) and $Config{$exe} ne '') {
#                 $self->{'_' . $exe} = $Config{$exe};
#             }
#         }
        return $self;
    }

=pod

=head2 backup(\@conf)

Makes the backup -- creates the backed up directory and archive
file.  @conf is an array where each element is either a string or
an array.  If it is a string, it is expected to be the path to a
directory that is to be backed up.  If the element is an array,
the first element is expected to be a directory that is to be
backed up, and the second should be the name the directory is
called once it has been copied to the backup directory.  The
return value is the name of the archive file created; unless
'no_archive' is set, then it will return an empty string.

=cut
    sub backup {
        my ($self, $conf) = @_;

        my $today = $self->_getTimestampForFileName;
        my $file_prefix = $self->getFilePrefix . $today;
        my $backup_dir = $self->getBackupDir;
        my $dst = "$backup_dir/$file_prefix";
	my $dst_file = '';
        mkdir $dst, 0755;

        my $cp = $self->getCpPath;
        foreach my $entry (@$conf) {
            if (ref($entry) eq 'ARRAY') {
                my ($dir, $name) = @$entry;
                $self->copy($dir, "$dst/$name");
            } else {
                $self->copy($entry, "$dst/");
            }
        }

	unless ( $self->{_no_archive} )
	{
		my $compress = $self->getCompressProgramPath;
		my $ext = $self->getCompressExtension;
		$ext = '.' . $ext unless $ext eq '';
		$dst_file = $dst . '.tar' . $ext;
		my $params = '-p';
		$params = '-v ' . $params if $self->_getVerbose;
		my $tar_cmd = $self->getTarPath . " $params -c -f - -C '$backup_dir' '$file_prefix'";
		system "$tar_cmd | $compress > $dst_file";
	}

        return $dst_file;
    }

=pod

=head2 rotate()

Rotates the backup directories and archive files.  The number of
archive files to keep and the number of directories to keep are
specified in the new() constructor.

=cut
    sub rotate {
        my ($self) = @_;
        my $archive_copies = $self->getArchiveCopies;
        my $dir_copies = $self->getDirCopies;
        my $backup_dir = $self->getBackupDir;
        my $secondary_backup_dir = $self->getSecondaryBackupDir;

        $self->_rotate($backup_dir, $archive_copies, $dir_copies, $secondary_backup_dir);

        return 1 if $secondary_backup_dir eq '';
        my $secondary_archive_copies = $self->getSecondaryArchiveCopies;
        $self->_rotate($secondary_backup_dir, $secondary_archive_copies, 0, '');
    }

=pod

=head2 my $archives = getArchiveDeleteList()

Returns a list of archive files that will get deleted if the
rotate() method is called.

=cut
    sub getArchiveDeleteList {
        my ($self) = @_;
        
        my $backup_dir = $self->getBackupDir;
        my $archives = $self->_getSortedArchives($backup_dir);
        my $num_archives = scalar(@$archives);
        my $archive_copies = $self->getArchiveCopies;

        my @files_to_delete;
        if ($num_archives > $archive_copies) {
            my $num_to_delete = $num_archives - $archive_copies;
            @files_to_delete = @$archives[0 .. $num_to_delete - 1];
        }

        @files_to_delete = map { "$backup_dir/$_" } @files_to_delete;

        return \@files_to_delete;
    }

=pod

=head2 my $dirs = getDirDeleteList()

Returns a list of directories that will get deleted if the
rotate() method is called.


=cut

    sub getDirDeleteList {
        my ($self) = @_;

        my $backup_dir = $self->getBackupDir;
        my $dirs = $self->_getSortedArchiveDirs($backup_dir);
        my $num_dirs = scalar(@$dirs);
        my $dir_copies = $self->getDirCopies;

        my @dirs_to_delete;
        if ($num_dirs > $dir_copies) {
            my $num_to_delete = $num_dirs - $dir_copies;
            @dirs_to_delete = @$dirs[0 .. $num_to_delete - 1];
        }

        @dirs_to_delete = map { "$backup_dir/$_" } @dirs_to_delete;
        
        return \@dirs_to_delete;
    }

    sub _rotate {
        my ($self, $backup_dir, $archive_copies, $dir_copies, $secondary_backup_dir) = @_;

        my $archives = $self->_getSortedArchives($backup_dir);
        my $num_archives = scalar(@$archives);
        my $dirs = $self->_getSortedArchiveDirs($backup_dir);
        my $num_dirs = scalar(@$dirs);

        if ($num_archives > $archive_copies) {
            my $num_to_delete = $num_archives - $archive_copies;
            my @files_to_delete = @$archives[0 .. $num_to_delete - 1];
            foreach my $file (@files_to_delete) {
                my $path = "$backup_dir/$file";
                unless ($secondary_backup_dir eq '') {
                    $self->copy($path, "$secondary_backup_dir/");
                }
                $self->_debugPrint("removing $path\n");
                $self->remove($path);
            }
        }

        if ($num_dirs > $dir_copies) {
            my $num_to_delete = $num_dirs - $dir_copies;
            my @dirs_to_delete = @$dirs[0 .. $num_to_delete - 1];
            foreach my $dir (@dirs_to_delete) {
                my $path = "$backup_dir/$dir";
                $self->_debugPrint("removing $path\n");
                $self->remove($path);
            }

        }
    }

    sub _debug {
        my ($self) = @_;
        return $$self{_debug};
    }

    sub _debugOff {
        my ($self) = @_;
        undef $$self{_debug};
        undef $$self{_debug_fh};
    }

    sub _debugOn {
        my ($self, $fh) = @_;
        $$self{_debug} = 1;
        $$self{_debug_fh} = $fh;
    }

    sub _debugPrint {
        my ($self, $str) = @_;
        return undef unless $$self{_debug};
        my $fh = $$self{_debug_fh};
        print $fh $str;
    }

    sub _getVerbose {
        my ($self) = @_;
        return $$self{_verbose};
    }

    sub _setVerbose {
        my ($self, $val) = @_;
        return $$self{_verbose} = $val;
    }

    sub _getUseFileLock {
        my ($self) = @_;
        return $$self{_use_flock};
    }
    
    sub _setUseFileLock {
        my ($self, $val) = @_;
        $$self{_use_flock} = $val;
    }

    sub _getUseRm {
        my ($self) = @_;
        return $$self{_use_rm};
    }

    sub _setUseRm {
        my ($self, $val) = @_;
        $$self{_use_rm} = $val;
    }

    sub copy {
        my ($self, $src, $dst) = @_;

        my $copy = $self->_getCopyObject;
        $copy->copy($src, $dst);
    }

    sub _getCopyObject {
        my ($self) = @_;
        my $copy = $$self{_copy_obj};
        unless ($copy) {
            $copy = File::Rotate::Backup::Copy->new({ use_flock => $self->_getUseFileLock,
                                                      use_rm => $self->_getUseRm
                                                    });
            $$self{_copy_obj} = $copy;
        }
        
        if ($$self{_debug}) {
            $copy->debugOn($$self{_debug_fh}, 1);
        } elsif ($self->_getVerbose) {
            $copy->debugOn(\*STDERR, 1);
        } else {
            $copy->debugOff;
        }
        
        return $copy;
    }

    sub remove {
        my ($self, $victim) = @_;

        my $remove = $self->_getCopyObject;
        $remove->remove($victim);
    }

    sub _getArchiveFileRegex {
        my $self = shift;
        my $prefix = quotemeta($self->getFilePrefix);
        my $regex;
        
        if (exists($self->{_archive_file_regex})) {
            $regex = $self->{_archive_file_regex};
        }
        else {
            $regex = '\d+-\d+-\d+_\d+_\d+_\d+';
        }

        $regex = $prefix . $regex;

        return $regex;
    }

    sub _getSortedArchives {
        my ($self, $dir) = @_;
        # my $prefix = quotemeta($self->getFilePrefix);
        $dir = $self->getBackupDir if $dir eq '';
        local(*DIR);
        opendir(DIR, $dir) or return undef;
        my $regex = $self->_getArchiveFileRegex;
        my @files = grep { m/^$regex/ and not -d "$dir/$_" } readdir DIR;
        closedir DIR;

        @files = sort { $a cmp $b } @files;
        return \@files;
    }

    sub _getArchiveDirRegex {
        my $self = shift;
        my $prefix = quotemeta($self->getFilePrefix);

        my $regex;
        if (exists($self->{_archive_dir_regex})) {
            $regex = $self->{_archive_dir_regex};
            $regex = '' unless defined $regex;
        }
        else {
            $regex = '\d+-\d+-\d+_\d+_\d+_\d+';
        }

        $regex = $prefix . $regex;

        return $regex;
    }

    sub _getSortedArchiveDirs {
        my ($self, $dir) = @_;
        # my $prefix = quotemeta($self->getFilePrefix);
        $dir = $self->getBackupDir if $dir eq '';
        local(*DIR);
        opendir(DIR, $dir) or return undef;
        # my @files = grep { m/^$prefix\d+-\d+-\d+_\d+_\d+_\d+/ and -d "$dir/$_" } readdir DIR;'
        my $regex = $self->_getArchiveDirRegex;
        my @files = grep { m/^$regex/ and -d "$dir/$_" } readdir DIR;
        closedir DIR;

        @files = sort { $a cmp $b } @files;
        return \@files;
    }

    sub _getTimestampForFileName {
        my ($self, $time) = @_;

        $time = time() unless $time;

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
        $mon += 1;
        $year += 1900;
        my $date = sprintf "%04d-%02d-%02d_%02d_%02d_%02d", $year, $mon, $mday,
            $hour, $min, $sec;

        return $date;
    }

    
    #################
    # getters/setters
    
    sub getCompressProgramPath {
        my ($self) = @_;
        my $path = $$self{_compress_program_path};
        if ($path eq '') {
            return $self->{_bzip2_path} || 'bzip2';
        }

        return $path;
    }

=pod

=head2 setCompressProgramPath($path)

Set the path to the compression program you want to use when
creating the archive files in the call to backup().  The given
compression program must provide the same API as gzip and bzip2,
at least to the extent that it will except input from stdin and
will write output to stdout when no file names are provided.
This defaults to 'bzip2' (no explicit path).

=cut
    sub setCompressProgramPath {
        my ($self, $path) = @_;
        $$self{_compress_program_path} = $path;
    }

    sub getCompressExtension {
        my ($self) = @_;
        
        if (exists($$self{_compress_ext})) {
            return $$self{_compress_ext};
        }

        my $compress_prog_path = $self->getCompressProgramPath;
        my $prog;
        if ($compress_prog_path =~ m{(?:\A|/)([^/\s]+)([^/]*)$}) {
            $prog = $1;
        }

        my $ext = { 'bzip2' => 'bz2',
                    'gzip' => 'gz',
                  }->{$prog};

        return $ext;
    }

=pod

=head2 setCompressExtension($ext)

This sets the extension given to the archive name after the .tar.
This defaults to .bz2 if bzip2 is used for compression, and .gz
if gzip is used.

=cut
    sub setCompressExtension {
        my ($self, $ext) = @_;
        $ext =~ s/^\.// unless $ext eq '.';
        $$self{_compress_ext} = $ext;
    }

    sub getTarPath {
        my ($self) = @_;
        my $path = $$self{_tar_path};
        if ($path eq '') {
            return 'tar';
        }
        
        return $path;
    }

=pod

=head2 setTarPath($path)

Set the path to the tar program.  This defaults to 'tar' (no
explicit path).

=cut
    sub setTarPath {
        my ($self, $path) = @_;
        $$self{_tar_path} = $path;
    }

    sub getRmPath {
        my ($self) = @_;
        my $path = $$self{_rm_path};
        if ($path eq '') {
            return '/bin/rm';
        }

        return $path;
    }

    sub setRmPath {
        my ($self, $path) = @_;
        $$self{_rm_path} = $path;
    }

    sub getCpPath {
        my ($self) = @_;
        my $path = $$self{_cp_path};
        if ($path eq '') {
            return 'cp';
        }

        return $path;
    }

    sub setCpPath {
        my ($self, $path) = @_;
        $$self{_cp_path} = $path;
    }

    sub getArchiveCopies {
        my ($self) = @_;
        return $$self{_archive_copies};
    }

    sub setArchiveCopies {
        my ($self, $num) = @_;
        $$self{_archive_copies} = $num;
    }

    sub getDirCopies {
        my ($self) = @_;
        return $$self{_dir_copies};
    }

    sub setDirCopies {
        my ($self, $num) = @_;
        $$self{_dir_copies} = $num;
    }

    sub getBackupDir {
        my ($self) = @_;
        return $$self{_backup_dir};
    }

    sub setBackupDir {
        my ($self, $dir) = @_;
        $$self{_backup_dir} = $dir;
    }

    # added for v0_02
    sub getSecondaryBackupDir {
        my ($self) = @_;
        return $$self{_secondary_backup_dir};
    }

    # added for v0_02
    sub setSecondaryBackupDir {
        my ($self, $dir) = @_;
        $$self{_secondary_backup_dir} = $dir;
    }

    sub getSecondaryArchiveCopies {
        my ($self) = @_;
        return $$self{_secondary_archive_copies};
    }

    sub setSecondaryArchiveCopies {
        my ($self, $num) = @_;
        $$self{_secondary_archive_copies} = $num;
    }

    sub getFilePrefix {
        my ($self) = @_;
        return $$self{_file_prefix};
    }

    sub setFilePrefix {
        my ($self, $prefix) = @_;
        $$self{_file_prefix} = $prefix;
    }
    

}

1;

__END__

=pod

=head1 AUTHOR

    Don Owens <don@regexguy.com>

=head1 CONTRIBUTORS

    Augie Schwer

=head1 COPYRIGHT

    Copyright (c) 2003-2007 Don Owens

    All rights reserved. This program is free software; you can
    redistribute it and/or modify it under the same terms as Perl
    itself.

=head1 VERSION

    0.13

=cut

