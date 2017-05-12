use ExtUtils::MakeMaker;
use Config qw(%Config); #for $Config{cc}
use Getopt::Long;

use strict;

my ($force_cflags, $force_cc) = ('', undef);
unless( GetOptions( 'cc=s'        => \$force_cc,
                    'cflags=s'    => \$force_cflags ) ) {
   die "usage: $0 [ -cc=/path/to/cc ] [ -cflags='-O -fPIC' ]\n".
       "       -cc is used to specify the path to the cc you would like to\n".
       "       use if autodetection fails. similarly for -cflags, which is\n".
       "       particularly useful when building with a different cc than\n".
       "       the one which was used to build perl. -cflags also accepts\n".
       "       the shortcut argument \"gcc\" which uses options for that\n".
       "       compiler.\n";
}
#TODO: is this general enough?
if($force_cflags eq 'gcc') {
   $force_cflags = '-O -g -fPIC -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64';
}


sub chk_sync () {
  # Work out -D... for Sync.o.

  # Apparently, OS/2 doesn't implement sync().
  if (defined $ExtUtils::MakeMaker::Is_OS2 and $ExtUtils::MakeMaker::Is_OS2) {
    warn "OS/2 doesn't implement sync() - making it a no-op.\n";
    return '';
  }

  return '-DHAVE_SYNC';
}

sub chk_fdatasync () {
  print "Testing if you have a working C compiler and the needed header files...\n";

  open(FH, ">.no_fdatasync") || die "internal error";
  close(FH) || die "internal error";

  unless(open(FH, ">compile.c")) {
    warn "cannot write compile.c, skipping fdatasync() support\n";
    return '';
  }

  print FH <<'EOF';
#include <sys/types.h>
#include <signal.h>
#include <errno.h>
#include <unistd.h>
int main() { fdatasync(0); return 0; }
EOF

  unless(close(FH)) {
    warn "cannot close compile.c, skipping fdatasync() support\n";
    return '';
  }

  #sometimes $Config{CC} is not the answer (e.g. solaris10 w/ gcc but
  #no sun c package installed)...
  my @cc_alternatives = ( $Config{cc}, qw( cc gcc egcs icc pcc lcc ));
  #if all fails but CC env var is set, try it, maybe it will link
  push @cc_alternatives, $ENV{CC} if($ENV{CC});
  unshift @cc_alternatives, $force_cc if(defined($force_cc));

  my ($ret, $CC);
  print "trying compilers: ";
  foreach my $cc ( @cc_alternatives )  {
    print "$cc... ";

    my $cmd = "$cc compile.c -o compile$Config{exe_ext}";
    $ret = system($cmd);
    if($ret==0) { $CC=$cc; last };
  }

  foreach my $file (glob('compile*')) {
    unlink($file) || warn "Could not delete $file: $!\n";
  }

  if ($ret == 0) {
    warn "fdatasync() support detected, including\n";
    unlink ".no_fdatasync";
    return '-DHAVE_FDATASYNC';
  } else {
    warn "fdatasync() support not detected, skipping it\n";
    return '';
  }
}

WriteMakefile(
  'NAME'	=> 'File::Sync',
  'VERSION_FROM' => 'Sync.pm', # finds $VERSION

  'DEFINE'	=> chk_sync().' '.chk_fdatasync(),

  'dist'	=> { COMPRESS => 'gzip -9', SUFFIX => 'gz' },
);
