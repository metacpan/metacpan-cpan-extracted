package Filesys::DiskUsage;

use warnings;
use strict;

use File::Basename;

use constant BYTES_PER_BLOCK => 512;

=head1 NAME

Filesys::DiskUsage - Estimate file space usage (similar to `du`)

=cut

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
        'all' => [ qw(
                        du
                ) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.11';

=head1 SYNOPSIS

  use Filesys::DiskUsage qw/du/;

  # basic
  $total = du(qw/file1 file2 directory1/);

or

  # no recursion
  $total = du( { recursive => 0 } , <*> );

or

  # max-depth is 1
  $total = du( { 'max-depth' => 1 } , <*> );

or

  # get an array
  @sizes = du( @files );

or

  # get a hash
  %sizes = du( { 'make-hash' => 1 }, @files_and_directories );

=head1 FUNCTIONS

=head2 du

Estimate file space usage.

Get the size of files:

  $total = du(qw/file1 file2/);

Get the size of directories:

  $total = du(qw/file1 directory1/);

=head3 OPTIONS

=over 6

=item blocks

Return the size based upon the number of blocks that the file occupies,
rather than the length of the file. The two values might be different
if the file is sparse.

This value should match more closely the value returned by the du(1)
command.

    $total = du( { blocks => 1 } , $dir );

=item dereference

Follow symbolic links. Default is 0. Overrides C<symlink-size>.

Get the size of a directory, recursively, following symbolic links:

  $total = du( { dereference => 1 } , $dir );

=item exclude => PATTERN

Exclude files that match PATTERN.

Get the size of every file except for dot files:

  $total = du( { exclude => qr/^\./ } , @files );

=item human-readable

Return sizes in human readable format (e.g., 1K 234M 2G)

  $total = du ( { 'human-readable' => 1 } , @files );

=item Human-readable

Return sizes in human readable format, but use powers of 1000 instead
of 1024.

  $total = du ( { 'Human-readable' => 1 } , @files );

=item make-hash

Return the results in a hash.

  %sizes = du( { 'make-hash' => 1 } , @files );

=item max-depth

Sets the max-depth for recursion. A negative number means there is no
max-depth. Default is -1.

Get the size of every file in the directory and immediate
subdirectories:

  $total = du( { 'max-depth' => 1 } , <*> );

=item recursive

Sets whether directories are to be explored or not. Set to 0 if you
don't want recursion. Default is 1. Overrides C<max-depth>.

Get the size of every file in the directory, but not directories:

  $total = du( { recursive => 0 } , <*> );

=item sector-size => NUMBER

All file sizes are rounded up to a multiple of this number.  Any file
that is not an exact multiple of this size will be treated as the next
multiple of this number as they would in a sector-based file system.  Common
values will be 512 or 1024.  Default is 1 (no sectors).

  $total = du( { sector-size => 1024 }, <*> );

=item show-warnings => 1 | 0

Shows warnings when trying to open a directory that isn't readable.

  $total = du( { 'show-warnings' => 0 }, <*> );

1 by default.

=item symlink-size => NUMBER

Symlinks are assumed to be this size.  Without this option, symlinks are
ignored unless dereferenced.  Setting this option to 0 will result in the
files showing up in the hash, if C<make-hash> is set, with a size of 0.
Setting this option to any other number will treat the size of the symlink
as this number.  This option is ignored if the C<dereference> option is
set.

  $total = du( { symlink-size => 1024, sector-size => 1024 }, <*> );

=item truncate-readable => NUMBER

Human readable formats decimal places are truncated by the value of
this option. A negative number means the result won't be truncated at
all. Default if 2.

Get the size of a file in human readable format with three decimal
places:

  $size = du( { 'human-readable' => 1 , 'truncate-readable' => 3 } , $file);

=back

=cut

my %all;
sub du {
  # options
  my %config = (
    'blocks'            => 0,
    'dereference'       => 0,
    'exclude'           => undef,
    'human-readable'    => 0,
    'Human-readable'    => 0,
    'make-hash'         => 0,
    'max-depth'         => -1,
    'recursive'         => 1,
    'sector-size'       => 1,
    'show-warnings'     => 1,
    'symlink-size'      => undef,
    'truncate-readable' => 2,
  );
  if (ref($_[0]) eq 'HASH') {%config = (%config, %{+shift})}
  $config{human} = $config{'human-readable'} || $config{'Human-readable'};

  my $calling_sub = (caller(1))[3];
  if (not defined $calling_sub or $calling_sub ne 'Filesys::DiskUsage::du') {
    %all = ();
  }
  my %sizes;

  # calculate sizes
  for (@_) {
    next if exists $all{$_};
    $all{$_} = 0;
    if (defined $config{exclude} and -f || -d) {
      my $filename = basename($_);
      next if $filename =~ /$config{exclude}/;
    }
    if (-l) { # is symbolic link
      if ($config{'dereference'}) { # we want to follow it
        $sizes{$_} = du( { 'recursive'   => $config{'recursive'},
                           'exclude'     => $config{'exclude'},
                           'sector-size' => $config{'sector-size'},
                           'blocks'      => $config{'blocks'},
                           'dereference' => $config{'dereference'},
                         }, readlink($_));
      }
      else {
        $sizes{$_} = $config{'symlink-size'} if defined $config{'symlink-size'};
        next;
      }
    }
    elsif (-f) { # is a file
      my @stat = stat(_);
      if (defined $stat[0]) {
        if ($config{blocks}) {
          $sizes{$_} = $stat[12] * BYTES_PER_BLOCK;
        } else {
          $sizes{$_}  = $config{'sector-size'} - 1 + $stat[7];
          $sizes{$_} -= $sizes{$_} % $config{'sector-size'};
        }
      }
    }
    elsif (-d) { # is a directory
      if ($config{recursive} && $config{'max-depth'}) {

        if (opendir(my $dh, $_)) {
          my $dir = $_;
          my @files = readdir $dh;
          closedir($dh);

          $sizes{$_} += du( { 'recursive'     => $config{'recursive'},
                              'max-depth'     => $config{'max-depth'} -1,
                              'exclude'       => $config{'exclude'},
                              'sector-size'   => $config{'sector-size'},
                              'blocks'        => $config{'blocks'},
                              'show-warnings' => $config{'show-warnings'},
                              'dereference' => $config{'dereference'},
                            }, map {"$dir/$_"} grep {! /^\.\.?$/} @files);
        }
        elsif ( $config{'show-warnings'} ) {
            # if the user requests to be notified of non openable directories, notify the user
            warn "could not open $_ ($!)\n";
        }

      }
    }
  }

  # return sizes
  if ( $config{'make-hash'} ) {
    for (keys %sizes) {$sizes{$_} = _convert($sizes{$_}, %config)}

    return wantarray ? %sizes : \%sizes;
  }
  else {
    if (wantarray) {
      return map {_convert($_, %config)} @sizes{@_};
    }
    else {
      my $total = 0;
      for (values %sizes) {$total += $_}

      return _convert($total, %config);
    }
  }

}

# convert size to human readable format
sub _convert {
  defined (my $size = shift) || return undef;
  my $config = {@_};
  $config->{human} || return $size;
  my $block = $config->{'Human-readable'} ? 1000 : 1024;
  my @args = qw/B K M G/;

  while (@args && $size > $block) {
    shift @args;
    $size /= $block;
  }

  if ($config->{'truncate-readable'} > 0) {
    $size = sprintf("%.$config->{'truncate-readable'}f",$size);
  }

  "$size$args[0]";
}

=head1 AUTHOR

Jose Castro, C<< <cog@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2004 Jose Castro, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Filesys::DiskUsage
