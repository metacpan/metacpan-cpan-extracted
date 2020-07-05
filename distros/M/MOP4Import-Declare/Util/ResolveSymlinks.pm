#!/usr/bin/env perl
package MOP4Import::Util::ResolveSymlinks;
use strict;
use warnings;
use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};
use Exporter;
our @EXPORT_OK = qw(normalize resolve_symlink resolve_symlink_1);

use File::Spec ();
use File::Basename ();

sub normalize {
  my ($filePath) = @_;

  my $realFn = -l $filePath ? resolve_symlink(__PACKAGE__, $filePath) : $filePath;

  File::Spec->rel2abs($filePath);
}

sub resolve_symlink {
  my ($pack, $filePath) = @_;

  print STDERR "# resolve_symlink($filePath)...\n" if DEBUG;

  (undef, my ($realDir)) = File::Basename::fileparse($filePath);

  while (defined (my $linkText = readlink $filePath)) {
    ($filePath, $realDir) = resolve_symlink_1($pack, $linkText, $realDir);
    print STDERR "# => $filePath (realDir=$realDir)\n" if DEBUG;
  }

  return $filePath;
}

sub resolve_symlink_1 {
  my ($pack, $linkText, $realDir) = @_;

  my $filePath = do {
    if (File::Spec->file_name_is_absolute($linkText)) {
      $linkText;
    } else {
      File::Spec->catfile($realDir, $linkText);
    }
  };

  if (wantarray) {
    # purify x/../y to y
    my $realPath = Cwd::realpath($filePath);
    (undef, $realDir) = File::Basename::fileparse($realPath);
    ($realPath, $realDir);
  } else {
    $filePath;
  }
}

unless (caller) {
  print __PACKAGE__->resolve_symlink(@ARGV), "\n";
}

1;
