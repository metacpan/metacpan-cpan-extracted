package File::Atomism::utils;

=head1 NAME

File::Atomism::utils - Misc file handling stuff

=head1 SYNOPSIS

Utilities for manipulating and creating filenames.

=head1 DESCRIPTION

A collection of standard perl functions and utilities for messing
with filenames.  These are generally useful for manipulating files
in an 'atomised' directory, see L<File::Atomism>.

=cut

use strict;
use warnings;

use File::stat;
use File::Spec;
use Exporter;
use File::Path qw /mkpath/;
use Sys::Hostname qw /hostname/;
use Time::HiRes qw /gettimeofday/;
use Cwd qw /abs_path/;

our $CONFDIR = $ENV{ATOMISM_CONF} || $ENV{HOME} ."/.atomism";

use vars qw /@ISA @EXPORT_OK/;
@ISA = qw /Exporter/;
@EXPORT_OK = qw /Hostname Pid Inode Unixdate Dir File Extension TempFilename PermFilename Journal Undo Redo/;

=pod

=head1 USAGE

Access some values useful for constructing temporary filenames:

   my $hostname = Hostname();
   my $pid = Pid();
   my $unixdate = Unixdate();

=cut

sub Hostname
{
    eval {hostname} || 'localhost.localdomain';
}

sub Pid
{
    $$;
}

sub Unixdate
{
    time;
}

=pod

Retrieve the inode of a file like so:

    my $inode = Inode ('/path/to/my-house.jpg');

=cut

sub Inode
{
    my $filename = shift;
    my $stat = stat ($filename) || return 0;
    $stat->ino;
}

=pod

Access the directory and filename given a path:

    Dir ('/path/to/my-house.jpg');
    File ('/path/to/my-house.jpg');

.returns '/path/to/' and 'my-house.jpg' respectively.

=cut

sub Dir
{
    my $path = shift;
    my ($volume, $dir, $file) = File::Spec->splitpath ($path);
    return $dir;
}

sub File
{
    my $path = shift;
    my ($volume, $dir, $file) = File::Spec->splitpath ($path);
    return $file;
}

=pod

Retrieve the file extension (.doc, .txt, .jpg) of a file like so:

    my $extension = Extension ('my-house.jpg');

=cut

sub Extension
{
    my $filename = shift;
    return 0 unless ($filename =~ /[^.]\.[a-z0-9_]+$/);
    $filename =~ s/.*\.//;
    $filename =~ s/[^a-z0-9_]//gi;
    return $filename;
}

=pod

Ask for a temporary filename like so:

    my $tempname = TempFilename ('/path/to/');
or
    my $tempname = TempFilename ('/path/to/myfile.yml');

A unique filepath based on the directory, hostname, current PID and
extension (if supplied, otherwise .tmp will be appended) will be
returned:

    /path/to/.foo.example.com-666.tmp
    /path/to/.foo.example.com-666.yml

=cut

sub TempFilename
{
    my $path = shift;
    my $ext = Extension ($path) || 'tmp';

    Dir ($path) .".". Hostname ."-". Pid .".". $ext;
}

=pod

Ask for a permanent filename like so:

    my $filename = PermFilename ('/path/to/.foo.example.com-666.yml');

A unique filepath based on the hostname, current PID, inode of the
temporary file, date and file extension will be supplied:

    /path/to/foo.example.com-666-1234-1095026759.yml

Alternatively you can specify the final extension as a second
parameter:

    my $filename = PermFilename ('/path/to/.foo.example.com-666.tmp', 'yml');

=cut

sub PermFilename
{
    my $path = shift;
    my $ext = shift || Extension ($path);

    Dir ($path) . Hostname ."-". Pid ."-". Inode ($path) ."-".  Unixdate .".". $ext;
}

=pod

Write to the undo buffer like so:

    Journal ([['persistent-file1.yml', '.temp-file1.yml'], [ ... ] ]);

=cut

sub Journal
{
    my $list = shift;

    # figure out where to put the journal from the first pair of files
    my $dir = Dir (abs_path ($list->[0]->[0])) || Dir (abs_path ($list->[0]->[1]));

    my $undodir = $CONFDIR ."/UNDO". $dir;
    my $redodir = $CONFDIR ."/REDO". $dir;
    mkpath ([$undodir, $redodir]);

    my $journal = $undodir . join (".", gettimeofday) .".patch";

    for my $item (@{$list})
    {
        my $old = abs_path ($item->[0]) || '/dev/null';
        my $new = abs_path ($item->[1]) || '/dev/null';

        `diff -u $old $new >> $journal;`;
    }
    system 'sync';
}

=pod

Undo the most recent change to the journal by supplying a directory
path to the Undo() method:

    Undo ('/path/to');

=cut

sub Undo
{
    my $dir = abs_path (shift);
    my $undodir = $CONFDIR ."/UNDO". $dir;
    my $redodir = $CONFDIR ."/REDO". $dir;

    opendir (DIR, $undodir) or warn "$!";
    my @files = sort (readdir (DIR));
    @files = grep !/^\./, @files;
    my $file = pop (@files) || return;

    my $undo = $undodir ."/". $file;
    my $redo = $redodir ."/". $file;

    `cd $dir; patch -p0 --batch --no-backup < $undo; cd -`;
    rename $undo, $redo;
    system 'sync';

    closedir (DIR);
}

=pod

Undo the most recent undo() with the Redo() method.  Usage is the
same as for Undo():

    Redo ('/path/to');

=cut

sub Redo
{
    my $dir = abs_path (shift);
    my $undodir = $CONFDIR ."/UNDO". $dir;
    my $redodir = $CONFDIR ."/REDO". $dir;

    opendir (DIR, $redodir) or warn "$!";
    my @files = sort (readdir (DIR));
    @files = grep !/^\./, @files;
    my $file = shift (@files) || return;

    my $undo = $undodir ."/". $file;
    my $redo = $redodir ."/". $file;

    `cd $dir; patch -p0 --force --no-backup < $redo; cd -`;
    rename $redo, $undo;
    system 'sync';

    closedir (DIR);
}

1;
