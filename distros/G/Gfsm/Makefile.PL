use ExtUtils::MakeMaker;

##----------------------------------------------------------------------
## Configuration
##----------------------------------------------------------------------
use Alien::Gfsm;
my %prereq = (
	      'ExtUtils::MakeMaker' => 6.52, ##-- for CONFIGURE_REQUIRES
	      'Alien::Gfsm' => 0.001,
	     );

##-- ensure mininum libgfsm version
use version;
my $gfsm_min_version = "0.0.15";
if (Alien::Gfsm->install_type ne 'system') {
  my $gfsm_alien_version = Alien::Gfsm->pkgconfig('gfsm')->keyword('Version');
  (my $v_alien = $gfsm_alien_version) =~ s/\-/_/g;
  die("Required library libgfsm >= v$gfsm_min_version not found; we have v$gfsm_alien_version\n")
    if (version->parse($v_alien) < version->parse($gfsm_min_version));
}
elsif (system("pkg-config --atleast-version=${gfsm_min_version} gfsm") != 0) {
  die("Required library libgfsm >= v$gfsm_min_version not found; we have v", `pkg-config --modversion gfsm`);
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
WriteMakefile
  (
   NAME		=> 'Gfsm',
   #DISTNAME	=> 'gfsm-perl',
   DISTNAME	=> 'Gfsm',
   AUTHOR       => 'Bryan Jurish <moocow@cpan.org>',
   ABSTRACT	=> 'Perl interface to libgfsm finite-state library',
   VERSION_FROM	=> 'Gfsm.pm',
   LICENSE => 'perl',

   ##-- prerequisites
   CONFIGURE_REQUIRES => \%prereq,
   PREREQ_PM => \%prereq,

   ##-- user variables
   #CC           => 'c++',   ##-- your c++ compiler
   LIBS         => Alien::Gfsm->libs,     ##-- additional ibraries
   INC          => Alien::Gfsm->cflags,   ##-- additional includes
   DEFINE       => '-DHAVE_CONFIG_H',     ##-- additional defines
   CCFLAGS      => '',         ##-- additional flags
   OPTIMIZE    => '-O2 -pipe', ##-- optimization flags
   OBJECT       => 'Gfsm.o GfsmPerl.o',

   ##-- install these
   EXE_FILES => [glob("bin/*.perl")],

   ##-- DEBUG
   #MAKEAPERL=>1,
   #LINKTYPE=>'static',
   #MAP_TARGET=>'gfsmperl',
   #CCFLAGS=>'-g',
   ##-- /DEBUG

   ##-- stuff that probably doesn't need to be changed
   #XSOPT        => '-C++',
   TYPEMAPS     => ['perlobject.map', 'typemap'],
  );


#-----------------------------------------------------------------------
# Extensions
#-----------------------------------------------------------------------
##...

sub MY::depend {
  package MY;
  my $inherited = shift->SUPER::depend(@_);
  $inherited .= (
		 "\n\n"
		 ##-- included xs dependencies
		 ."Gfsm.c: "
		 .(''
		   ." Gfsm.xs"
		   ." Constants.xs"
		   ." Semiring.xs"
		   ." Alphabet.xs"
		   ." Automaton.xs"
		   ." Algebra.xs"
		   ." Arith.xs"
		   ." ArcIter.xs"
		   ." Encode.xs"
		   ." Lookup.xs"
		   ." Paths.xs"
		   ." Trie.xs"
		   ." Indexed.xs"
		   ." StateSort.xs"
		  )
		 ."\n\n"
		 ##-- c->o dependencies
		 ."Gfsm.o: Gfsm.c GfsmPerl.h\n"
		 ."\n"
		 ."GfsmPerl.o: GfsmPerl.h GfsmPerl.c\n"
		 ."\n"
		 ## -- more here
		 ."\n"
		);
  $inherited;
}

