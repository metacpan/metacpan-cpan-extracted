#!/usr/bin/perl -w

package File::Set;

=head1 NAME

File::Set - Mange/build a set of files from a list of file/directories

=head1 SYNOPSIS

  use File::Set;

  $FS = File::Set->new();

  # Add directories (and implicitly all files and sub-dirs) to file set
  $FS->add('/etc');
  $FS->add('/usr/lib', '/usr/include');
  # Add files in directory (not recursive);
  $FS->add({ recurse => 0 }, '/usr/local/bin');

  # Exclude particular files/directories
  $FS->exclude('/usr/include/linux', '/etc/shadow');

  # Add/exclude from file (see below for file format)
  $FS->add_from_file('/tmp/config');

  # List files, calling callback for each dir/file
  $FS->list($self, \&list_callback, 0);

  # Save a list of checksums for all files/directories
  $FS->save_checksum_db('/tmp/checksumdb');

  # Compare a list against a previously saved checksum db
  #  and call callback for added/deleted/changed files
  $FS->compare_checksum_db('/tmp/checksumdb', \&callback)

  sub list_callback {
    my ($self, $prefix, $path, $type, $stat) = @_;
    ... called back for each file/dir/etc found ...
  }


=head1 DESCRIPTION

This module is designed to build and manipulate a set of files
from a list of input directories and files. You can specify
whether directories should be recursed or not, or specific
sub-directories ignored.

=cut

# Use modules {{{
our $VERSION = '1.02';

use Cwd;
use Digest::MD5;
use File::Temp qw(tempfile);
use strict;
# }}}

=head1 METHODS

=over 4
=cut

=item I<new()>

Create a new fileset object. Any parameters
are passed straight to the C<add()> method

=cut
sub new {
  my $Proto = shift;
  my $Class = ref($Proto) || $Proto;

  my $Self = bless { }, $Class;
  $Self->{Paths} = [ ];
  $Self->{Excludes} = { };
  $Self->{Prefix} = '';

  $Self->add(@_) if @_;

  return $Self;
}

=item I<prefix($path)>

Sets a path 'prefix' that's prepended to all paths before
they are used.

=cut
sub prefix {
  my $Self = shift;

  $Self->{Prefix} = shift;
}

=item I<add([ $Opts ], $path1, $Path2, ...)>

Add the given paths to the file set.

C<$Opts> is an option hash-reference of options.

=over 4

=item B<recurse>

Set if we should recurse into sub-folders as well. True by default

=item B<exclude>

Set if we should exclude this file/path rather than add it

=back

=cut
sub add {
  my $Self = shift;

  # Grab options hash ref
  my %Opts = ref $_[0] ? %{ +shift } : ();

  # By default recurse if not explicity specified
  $Opts{recurse} = 1 if !exists $Opts{recurse};

  while (@_) {
    $_ = shift @_;

    # Make local copy
    my %LOpts = %Opts;

    # Override if special path prefix
    $LOpts{recurse} = 0 if s/^\@//;
    $LOpts{exclude} = 1 if s/^\!//;

    $_ = canon_path($_);

    # If excluding, add to exclusion hash
    if ($LOpts{exclude}) {
      $Self->{Excludes}->{$_} = 1;

    # Otherwise add to paths list
    } else {
      push @{$Self->{Paths}}, [ $_, \%LOpts ];
    }
  }

}

=item I<exclude([ $Opts ], $path1, $Path2, ...)>

Exclude the given paths from the file set.

Like calling C<add()> with the C<exclude> option set to true

=cut
sub exclude {
  my $Self = shift;

  # Grab options hash ref
  my $Opts = ref $_[0] ? shift : { };

  # Just call add() with exclude option set to 1
  $Opts->{exclude} = 1;
  $Self->add($Opts, @_);
}

=item I<add_from_file($file)>

Open the given file and add the paths to the fileset

The file can have:

=over 4

=item *

Blank lines which are ignored

=item *

Lines beginning with # which are ignored

=item *

A line with a single path to a file/directory.

=back

Optionally each line with a path can begin with:

=over 4

=item B<!>

To exclude the path rather than add it

=item B<@>

To add the path non-recursively

=back

=cut
sub add_from_file {
  my $Self = shift;

  my $Fh = shift;
  if (!ref $Fh) {
    my $FilePath = $Fh;
    open($Fh, $FilePath)
      || die "Could not open '$FilePath' for reading: $!";
  }

  while (<$Fh>) {
    chomp;
    next if /^#/;
    next if /^\s*$/;

    $Self->add($_);
  }

}

=item I<get_path_list()>

Return an array of all paths added/excluded

Each item as an array-ref of 2 items. The first item is the path
and the second item is the hash-ref of options

=cut
sub get_path_list {
  my $Self = shift;

  return @{$Self->{Paths}};
}

=item I<canon_path($path1, $Path2, ...)>

Cleanup the given paths to a consistent form

=cut
sub canon_path {
  my @Paths = @_;

  for (@Paths) {
    s{//}{/}g;
    s{^\./}{};
    s{/\.(?:/|$)}{/}g;
    s{^\.\./[^/]+/}{};
    s{/\.\./[^/]+(?:/|$)}{/}g;
    s{/$}{};
  }
  return wantarray ? @Paths : $Paths[0];
}

=item I<list($Context, $Callback, $ErrorHandler)>

The main method call. Iterates through all dirs, sub-dirs and
files added through C<add()> but not excluded through C<exclude()>

For each file/directory calls code-ref C<$Callback> passing
C<$Context> as the first parameter. Additional parameters are:

=over 4

=item C<$Prefix>

Prefix set with the C<prefix()> call or '' if none

=item C<$Path>

Full path of this file/directory

=item C<$Type>

A string describing the type of the file/dir

=over 4

=item f - a file

=item d - a directory

=item l - a symlink

=item u - other

=back

=item C<$Stat>

A hash-ref of information from the C<lstat()> system call:
Dev Ino Mode NLink Uid Gid RDev Size ATime MTime CTime BlkSize Blocks

=back

The $ErrorHandler parameter controls error handling during the recursion.
This can happen for instance if files/directories are deleted during
the traversal.

=over 4

=item C<false (eg undef/0/"")>

If not passed or false value, then any errors are ignored

=item C<true (eg 1)>

If true, then any errors cause a die to occur

=item C<sub-ref>

If a sub ref, then the sub ref is called with the file/directory
name that went missing during the traversal

=back

=cut
sub list {
  my ($Self, $Context, $ListCB, $ErrorHandler) = @_;
  $ListCB || die "No callback passed";

  my ($Paths, $Excludes, $Prefix, $Opts) = @$Self{qw(Paths Excludes Prefix)};
  @_ = @$Paths;

  while ($_ = shift @_) {
    ($_, $Opts) = @$_;

    # Skip if a no-go path
    next if $Excludes->{$_};

    # Stat to find type
    my %Stat = (Path => $_);
    @Stat{qw(Dev Ino Mode NLink Uid Gid RDev Size ATime MTime CTime BlkSize Blocks)}
      = lstat("$Prefix/$_");

    if (!-e _)   {
      next if !$ErrorHandler;
      $ErrorHandler->("$Prefix/$_") if ref($ErrorHandler);
      die "Could not stat '$Prefix/$_': $!";
    }
    elsif (-f _) { $Stat{Type} = 'f'; }
    elsif (-l _) { $Stat{Type} = 'l'; }
    elsif (-d _) {

      # If not recursing, pretend this dir doesn't even exist...
      next if $Opts->{recurse} < 0;

      # Copy $Opts for recurse. Set to -1 if not recursing. Will catch
      #  all contained files, but sub-dirs will be skipped by above conditional
      my %Opts = %$Opts;
      $Opts{recurse}-- if !$Opts{recurse};
      $Stat{Type} = 'd';

      my $Path = $_;
      my $Dh;
      if (!opendir($Dh, "$Prefix/$_")) {
        next if !$ErrorHandler;
        $ErrorHandler->("$Prefix/$_") if ref($ErrorHandler);
        die "Could not open '$Prefix/$_' for dir reading: $!";
      }
      my @Entries = grep { !/^(?:\.|\.\.)$/ } readdir($Dh);
      close($Dh);
      push @_, map { [ canon_path("$Path/$_"), \%Opts ] } @Entries;
      
    } else {
      $Stat{Type} = 'u';
    }

    $ListCB->($Context, $Prefix, $_, $Stat{Type}, \%Stat);
  }
}

=item I<save_checksum_db($DbFile)>

Uses the C<list()> method to iterate through added paths,
and outputs a checksum of information about all dirs/files
to $DbFile.

For all files this includes mode, gid, uid, size. For files
this also includes the md5 checksum.

Can be used for the c<compare_checksum_db()> call below

=cut
sub save_checksum_db {
  my $Self = shift;
  
  my $DbFilePath = shift || die "No db file path supplied";

  open(my $Fh, ">$DbFilePath") || die "Could not open '$DbFilePath': $!";
  $Self->list($Self, sub { print $Fh join(',', &_generate_checksum, $_[2]), "\n"; });
  close($Fh);
}

=item I<compare_checksum_db($DbFile, $Context, $Callback)>

Uses the C<list()> method to iterate through added paths,
and compares to the contents of the C<$DbFile> file. If
any files or directories have changed, calls the C<$Callback>
code-ref with C<$Context> as the first parameter. Additional
parameters are:

=over 4

=item C<$Action>

Action that occured on the file

=over 4

=item n - new

=item c - changed

=item d - deleted

=back

=item C<$Type>

Type of file/dir (see above)

=item C<$Prefix>

Prefix set with the C<prefix()> call or '' if none

=item C<$Path>

Path to file

=back

=cut
sub compare_checksum_db {
  my $Self = shift;

  my $DbFilePath = shift || die "No db file path supplied";
  my $Context = shift;
  my $CompareCB = shift || die "No callback supplied";

  my %DbContents;

  open(my $Fh, $DbFilePath) || die "Could not open '$DbFilePath': $!";
  while (<$Fh>) {
    chomp;
    @_ = split /,/, $_, 8;
    my $Path = pop @_;
    $DbContents{$Path} = [ @_ ];
  }
  close($Fh);

  $Self->{DbContents} = \%DbContents;
  $Self->{CompareCB} = $CompareCB;
  $Self->{Context} = $Context;

  $Self->list($Self, \&_compare_checksum);

  for (keys %DbContents) {
    $CompareCB->($Self->{Context}, 'd', $DbContents{$_}->[0], $Self->{Prefix}, $_);
  }
}

=item I<create_gnu_tar($TarFile)>

Create a tar file containing the added paths

Correctly creates .tar.gz and .tar.bz2 files

=cut
sub create_gnu_tar {
  my $Self = shift;

  my $TarFile = shift;

  # Remove any existing
  unlink $TarFile if -f $TarFile;

  my $Cwd = getcwd();

  # Make paths relative to cwd if prefix
  chdir($Self->{Prefix} || '/');

  # Create a temporary file to store files to put in archive
  my ($Fh, $FileList) = tempfile(DIR => '/tmp');

  # List files and add to tempfile list
  $Self->list($Self, sub {
    my ($Self, $Prefix, $Path, $Type, $Stat) = @_;
    # Skip directories
    return if $Type eq 'd';
    print $Fh canon_path("./$Path"), "\n";
  });
  close ($Fh);

  my $Flags = '-cf';
  $Flags = '-czf' if $TarFile =~ /gz$/;
  $Flags = '-cjf' if $TarFile =~ /bz2$/;

  # Now create tar file from file list
  system('/bin/tar', $Flags, $TarFile, '-T', $FileList);

  chdir $Cwd;
}

sub _generate_checksum {
  my ($Self, $Prefix, $Path, $Type, $Stat) = @_;

  # Get stat params
  my ($Mode, $Uid, $Gid, $Size, $MTime, $Md5)
    = @$Stat{qw(Mode Uid Gid Size MTime)};

  # If it's a file, generate md5 hash
  if ($Type eq 'f') {
    open(my $Fh, "$Prefix/$_") || die "Could not open '$Prefix/$_' for reading: $!";
    $Md5 = Digest::MD5->new()->addfile($Fh)->b64digest;
    close($Fh);
  }

  return ($Type, $Mode, $Uid, $Gid, $Size, $MTime, $Md5 || '');
}

sub _compare_checksum {
  my ($Self, $Prefix, $Path, $Type, $Stat) = @_;

  my ($DbContents, $CompareCB) = @$Self{qw(DbContents CompareCB)};

  my $Existing = delete $DbContents->{$Path};
  if (!$Existing) {
    $CompareCB->($Self->{Context}, 'n', $Type, $Self->{Prefix}, $Path);
  } else {
    my @NewDetails = _generate_checksum(@_);
    my @ExistingDetails = @$Existing;

    if ("@NewDetails" ne "@ExistingDetails") {
      $CompareCB->($Self->{Context}, 'c', $Type, $Self->{Prefix}, $Path);
    }
  }
}

=back
=cut

=head1 SEE ALSO

L<mtree>

Latest news/details can also be found at:

L<http://cpan.robm.fastmail.fm/fileset/>

=cut

=head1 AUTHOR

Rob Mueller E<lt>L<mailto:cpan@robm.fastmail.fm>E<gt>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008 by FastMail IP Partners

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

