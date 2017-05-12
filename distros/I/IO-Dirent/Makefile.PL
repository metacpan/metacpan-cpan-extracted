use strict;
use Config qw(%Config);
use ExtUtils::MakeMaker;

my @extra  = ();
my @define = ();
#@extra = (DEFINE => "@define") if @define = defines();

WriteMakefile(
    'NAME'	   => 'IO::Dirent',
    'VERSION_FROM' => 'Dirent.pm', # finds $VERSION
    @extra,
    'dist'         => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);

sub defines {
    my %tests   = ();
    my @results = ();

    $| = 1;

    open TEST, ">t.c" or die "$!";
    print TEST <<_CODE_; close TEST;
#include <sys/dirent.h>
#include <stdio.h>
int main() 
{
  struct dirent *dent;
  DIR           *dir = opendir(".");
  if( !dir )
    return -1;

  while( dent = readdir(dir) ) {
      if( dent->d_name[0] == '.' && dent->d_name[1] == '.' && dent->d_name[2] == 0 ) {
          fprintf(stderr, "Type directory: %d\n", dent->d_type);
      }
      else {
	  continue;
      }
  }
  closedir (dir);
}
_CODE_

    push @results, ( compile_run() ? '-DHAS_D_TYPE' : () );

    return @results;
}

sub compile_run {
    my $cc_cmd = "$Config{cc} $Config{ccflags} -I$Config{archlibexp}/CORE";
    my $exe    = "_t_phony$Config{_exe}";

    if ($^O eq 'MSWin32') {
        $cc_cmd .= ' -DWIN32IO_IS_STDIO';
    } else {
        $cc_cmd .= " -o $exe";
    }

    my $rc = system("$cc_cmd $Config{ldflags} t.c $Config{libs} > /dev/null 2>&1");
    if ($rc) {
        unlink("t.c", $exe, "t$Config{_o}");
        return;
    }

    $rc = system("./$exe 2>&1 > /dev/null");
    unlink("t.c", $exe, "t$Config{_o}");

    return ( $rc ? 0 : 1 );
}
