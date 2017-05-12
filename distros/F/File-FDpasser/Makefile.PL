use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# add to this list as needed

%ostofile=(linux=>'bsd44.o',
	   bsdos=>'bsd44.o',
	   openbsd=>'bsd44.o',
	   freebsd=>'bsd44.o',
	   netbsd=>'bsd44.o',
	   solaris=>'svr4.o',
	   dec_osf=>'bsd44.o',
	   irix=>'bsd43.o',
	   hpux=>'bsd43.o',
	   aix=>'bsd44.o',
	   darwin=>'bsd44.o');

if (!defined($ostofile{$^O})) { die "No support for os: $^O\nEdit makefile.pl and send mail to amh\@mbl.is\n"; }

$DEF='';
if ($^O eq 'dec_osf') { $DEF='-D_SOCKADDR_LEN'; }
#if ($^O eq 'hpux') { $DEF='-D_XOPEN_SOURCE_EXTENDED'; }

WriteMakefile(
	      'NAME'	=> 'File::FDpasser',
	      'VERSION_FROM' => 'FDpasser.pm', # finds $VERSION
	      'LIBS'	=> [''],   # e.g., '-lm' 
	      'OBJECT'	=> $ostofile{$^O}.' FDpasser.o',
	      'DEFINE'	=> $DEF,     # e.g., '-DHAVE_SOMETHING' 
	      'INC'	=> '',     # e.g., '-I/usr/include/other' 
);
