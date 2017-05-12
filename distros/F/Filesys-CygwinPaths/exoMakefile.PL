use ExtUtils::ExoBuild;
use Cwd qw(getcwd);

my $mm_SRCDIR = q(/cdv/h/src/working/perl-modules/Filesys);
my $pp_SRCDIR = $mm_SRCDIR . q(/);
my $exo_builddir = getcwd;

#------------------------------------------------------------------------
my $inst = "$exo_builddir/blib";
my %exoatt = (
        INST_LIB        => "$inst/lib",
        INST_ARCHLIB    => "$inst/arch",
        INST_BIN        => "$inst/bin",
        INST_MAN1DIR    => "$inst/man1",
        INST_MAN3DIR    => "$inst/man3",
        INST_SCRIPT     => "$inst/script",
        SKIP => [ qw( selfdocument makefile perldepend
                      staticmake makeaperl ) ],

 );

BEGIN {
  if( not $^O =~/cygwin/i ) {
	die "Sorry, you cannot build this module on a non-Cygwin Perl.\n";
  }
}

# Subject to change -- but with with present EU::MM don't know WHAT
# this does anyway!
my $funct =  [ qw{
  XS_Filesys__CygwinPaths_cygwin_conv_to_full_posix_path
  XS_Filesys__CygwinPaths_cygwin_conv_to_full_win32_path
  XS_Filesys__CygwinPaths_cygwin_conv_to_posix_path
  XS_Filesys__CygwinPaths_cygwin_conv_to_win32_path
  } ];

my %stdatt = (
    'NAME'		=> 'Filesys::CygwinPaths',
    'VERSION_FROM'	=> 'lib/Filesys/CygwinPaths.pm',
    ($] >= 5.005 ?
      (ABSTRACT_FROM 	=> 'lib/CygwinPaths.pm',
       AUTHOR     	=> 'Soren Andersen <somian@pobox.com>') : ()),
	'PM'    => { 'lib/CygwinPaths.pm' => '$(INST_LIBDIR)/CygwinPaths.pm' },
	'INC'	=> '-I. -I$(SRCDIR)',
	'XS'        => { 'path_protocol.xs' => 'path_protocol.c' },
	'TYPEMAPS'  => [ 'Cygwin.typemap' ],
	'H'         => [ 'path_protocol.h'],
	'OBJECT'    => 'path_protocol.o',
	'FUNCLIST'  => $funct,
	'OPTIMIZE'  => '-O2 -g -Wundef',
	'LD'        => 'gcc -shared',
	'CCDLFLAGS' => '',
#	'CCFLAGS'   => '-DPERL_USE_SAFE_PUTENV -fno-strict-aliasing',
	'dist'      => { COMPRESS => gzip, SUFFIX => '.gz'},
);
   my $exo=ExtUtils::ExoBuild->exobuilder($mm_SRCDIR,$exo_builddir, %exoatt,%stdatt);
   $exo->WriteExoMakefile();

