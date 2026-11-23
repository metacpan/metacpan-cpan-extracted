#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use File::DistDir;

my $tmp    = tempdir( CLEANUP => 1 );
my $share  = File::Spec->catdir( $tmp,   'share' );
my $config = File::Spec->catdir( $share, 'config' );
make_path($config);

_write( File::Spec->catfile( $config, 'a.txt' ),    "alpha\n" );
_write( File::Spec->catfile( $share,  'root.txt' ), "root\n" );

{
  no warnings 'redefine';
  local *File::DistDir::dist_dir = sub {
    my ($distribution) = @_;
    die 'Unexpected distribution' if $distribution ne 'Fixture-Dist';
    return $share;
  };

  my $dist = File::DistDir->new( distribution => 'Fixture-Dist' );

  isa_ok( $dist, 'File::DistDir' );
  is( $dist->dir,                  abs_path($share),                                    'dir returns installed share root' );
  is( $dist->path('config/a.txt'), abs_path( File::Spec->catfile( $config, 'a.txt' ) ), 'path resolves resource' );
  is_deeply( [ $dist->list ], [qw(config config/a.txt root.txt)], 'list returns sorted relative paths' );

  my $file_dest = File::Spec->catfile( $tmp, 'copy.txt' );
  ok( $dist->copy( 'config/a.txt', $file_dest ), 'copy a file to a new filename' );
  is( _read($file_dest), "alpha\n", 'copied file contents match' );

  my $directory_dest = File::Spec->catdir( $tmp, 'output' );
  ok( $dist->copy( 'config', $directory_dest, recursive => 1 ), 'copy directory contents to a new directory' );
  is( _read( File::Spec->catfile( $directory_dest, 'a.txt' ) ),
    "alpha\n", 'directory contents copied without additional level' );

  my $all_dest = File::Spec->catdir( $tmp, 'all' );
  ok( $dist->copy( '.', $all_dest, recursive => 1 ),          'copy entire share directory' );
  ok( -f File::Spec->catfile( $all_dest, 'config', 'a.txt' ), 'nested resources copied' );
  ok( -f File::Spec->catfile( $all_dest, 'root.txt' ),        'root resources copied' );

  my $saved_cwd = getcwd();
  my $cwd_dest  = File::Spec->catdir( $tmp, 'working' );
  make_path($cwd_dest);
  chdir $cwd_dest or die "Cannot chdir to $cwd_dest: $!";
  ok( $dist->copy( '.', undef, recursive => 1 ),       'copy dot with omitted destination' );
  ok( -f File::Spec->catfile( $cwd_dest, 'root.txt' ), 'default destination is current directory' );
  chdir $saved_cwd or die "Cannot return to $saved_cwd: $!";

  my $error = eval { $dist->copy( 'config', $file_dest ); 1 };
  ok( !$error, 'directory copy requires recursive option' );
  like( $@, qr/recursive/, 'directory-copy error identifies missing option' );

  $error = eval { $dist->path('../outside'); 1 };
  ok( !$error, 'path traversal rejected' );

  $error = eval { $dist->copy( '.', File::Spec->catdir( $config, 'inside' ), recursive => 1 ); 1 };
  ok( !$error, 'destination within source rejected' );

  my $external = File::Spec->catfile( $tmp, 'outside.txt' );
  _write( $external, "outside\n" );
  if ( symlink( $external, File::Spec->catfile( $share, 'outside-link' ) ) ) {
    $error = eval { $dist->copy( '.', File::Spec->catdir( $tmp, 'linked' ), recursive => 1 ); 1 };
    ok( !$error, 'recursive copy rejects symlinks' );
  }
  else {
    pass('symlink test unavailable on this platform');
  }

  # A symlink in an intermediate source component must not bypass the
  # source-symlink policy, even when it points back inside the share tree.
  my $source_alias = File::Spec->catdir( $share, 'config-alias' );
  if ( symlink( $config, $source_alias ) ) {
    my $alias_dest = File::Spec->catfile( $tmp, 'alias-copy.txt' );
    $error = eval { $dist->copy( 'config-alias/a.txt', $alias_dest ); 1 };
    ok( !$error, 'copy rejects intermediate source directory symlinks' );
    ok( !-e $alias_dest, 'rejected source symlink does not create a destination file' );
  }
  else {
    pass('intermediate source symlink test unavailable on this platform');
    pass('intermediate source symlink destination check unavailable on this platform');
  }

  # A destination symlink must not redirect a recursive copy outside the
  # requested destination tree.
  my $outside_dir = File::Spec->catdir( $tmp, 'outside-directory' );
  my $dest_alias  = File::Spec->catdir( $tmp, 'destination-alias' );
  make_path($outside_dir);
  if ( symlink( $outside_dir, $dest_alias ) ) {
    $error = eval { $dist->copy( 'config', $dest_alias, recursive => 1 ); 1 };
    ok( !$error, 'recursive copy rejects a symlink destination directory' );
    ok( !-e File::Spec->catfile( $outside_dir, 'a.txt' ),
      'rejected destination symlink does not write outside the destination tree' );
  }
  else {
    pass('destination directory symlink test unavailable on this platform');
    pass('destination symlink containment check unavailable on this platform');
  }
}

done_testing;

sub _write {
  my ( $file, $content ) = @_;
  open my $fh, '>', $file or die "Cannot write $file: $!";
  print {$fh} $content;
  close $fh or die "Cannot close $file: $!";
  return;
}

sub _read {
  my ($file) = @_;
  open my $fh, '<', $file or die "Cannot read $file: $!";
  local $/;
  my $content = <$fh>;
  close $fh;
  return $content;
}
