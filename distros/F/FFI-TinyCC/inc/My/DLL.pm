package My::DLL;

use strict;
use warnings;
use autodie;
use Alien::TinyCC;
use Archive::Ar 2.02;
use File::Temp qw( tempdir );
use File::Glob qw( bsd_glob );
use Config;
use File::Basename qw( dirname basename );
use base qw( Exporter );
use File::Copy qw( copy );
use Path::Tiny qw( path );
use File::chdir;

our @EXPORT = qw( tcc_clean tcc_build tcc_name );

my $share = path(__FILE__)
  ->absolute
  ->parent
  ->parent
  ->parent
  ->child('share');

my $log = $share->child('build.log')->opena;

sub tcc_clean
{
  print $log "--- clean ", time, '---', "\n";
  for(grep { $_->basename =~ /^libtcc\./ } $share->children)
  {
    print $log "unlink $_", "\n";
    unlink $_;
  }
  if(-d $share->child('lib'))
  {
    for($share->child('lib')->children)
    {
      print $log "unlink $_", "\n";
      unlink $_;
    }
    print $log "rmdir " . $share->child('lib'), "\n";
    rmdir $share->child('lib');
  }
}

sub tcc_build
{
  tcc_clean();
  
  print $log "--- build ", time, '---', "\n";

  my $libdir = path(Alien::TinyCC->libtcc_library_path)->absolute;

  if($^O eq 'MSWin32')
  {
    do {
      my $from = $libdir->child('libtcc.dll');
      my $to   = tcc_name();
      print $log "copy $from => $to", "\n";
      copy($from => $to)
      || die "unable to copy $from => $to $!";
    };

    $share->child('lib')->mkpath;
    
    foreach my $file ($libdir->child('lib')->children)
    {
      my $from = $file;
      my $to   = $share->child('lib', basename $file);
      print $log "copy $from $to", "\n";
      copy($from => $to)
      || die "unable to copy $from => $to $!";
    }
  }
  else
  {
    my $lib = $libdir->child('libtcc.a');
    print $log "lib = $lib", "\n";

    die "unable to find libtcc.a" unless -f $lib;

    my $tmp = path(tempdir( CLEANUP => 1 ));
    print $log "tmp = $tmp", "\n";

    do {
      local $CWD = $tmp;
      my $ar = Archive::Ar->new;
      $ar->read($lib->stringify);
      foreach my $old ($ar->list_files)
      {
        my $new = $old;
        $new =~ s{\0+$}{};
        next if $new eq $old;
        $ar->rename($old, $new);
      }
      $ar->extract || die $ar->error;
    };
    my @obj = grep /\.(o|obj)$/, $tmp->children;
    print $log "obj = $_", "\n" for @obj;

    my @cmd = ($Config{cc}, '-o' => tcc_name(), '-shared', @obj);
    print $log "+ @cmd\n";

    print "+ @cmd\n";
    system @cmd;
    die if $?;
  }
}

sub tcc_name
{
  $^O eq 'MSWin32' ? $share->child('libtcc.dll') : $share->child("libtcc.$Config{dlext}");
}

1;
