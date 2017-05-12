package My::DLL;

use strict;
use warnings;
use autodie qw( :all );  # need IPC::System::Simple
use Alien::TinyCC;
use Archive::Ar 2.02;
use File::Temp qw( tempdir );
use File::Glob qw( bsd_glob );
use Config;
use File::Basename qw( dirname basename );
use base qw( Exporter );
use File::Copy qw( copy );
use Path::Class::File ();
use File::chdir;

our @EXPORT = qw( tcc_clean tcc_build tcc_name );

my $share = Path::Class::File
  ->new(dirname $INC{'My/DLL.pm'})
  ->absolute
  ->dir
  ->parent
  ->subdir('share');

my $log = $share->file('build.log')->opena;

sub tcc_clean
{
  print $log "--- clean ", time, '---', "\n";
  for(grep { $_->basename =~ /^libtcc\./ } $share->children)
  {
    print $log "unlink $_", "\n";
    unlink $_;
  }
  if(-d $share->subdir('lib'))
  {
    for($share->subdir('lib')->children)
    {
      print $log "unlink $_", "\n";
      unlink $_;
    }
    print $log "rmdir " . $share->subdir('lib'), "\n";
    rmdir $share->subdir('lib');
  }
}

sub tcc_build
{
  tcc_clean();
  
  print $log "--- build ", time, '---', "\n";

  my $libdir = Path::Class::Dir->new(
    Alien::TinyCC->libtcc_library_path,
  )->absolute;

  if($^O eq 'MSWin32')
  {
    do {
      my $from = $libdir->file('libtcc.dll');
      my $to   = tcc_name();
      print $log "copy $from => $to", "\n";
      copy($from => $to)
      || die "unable to copy $from => $to $!";
    };

    $share->subdir('lib')->mkpath(0, 0755);
    
    foreach my $file ($libdir->subdir('lib')->children)
    {
      my $from = $file;
      my $to   = $share->file('lib', basename $file);
      print $log "copy $from $to", "\n";
      copy($from => $to)
      || die "unable to copy $from => $to $!";
    }
  }
  else
  {
    my $lib = $libdir->file('libtcc.a');
    print $log "lib = $lib", "\n";

    die "unable to find libtcc.a" unless -f $lib;

    my $tmp = Path::Class::Dir->new(tempdir( CLEANUP => 1 ));
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
  $^O eq 'MSWin32' ? $share->file('libtcc.dll') : $share->file("libtcc.$Config{dlext}");
}

1;
