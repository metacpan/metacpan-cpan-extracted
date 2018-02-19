use ExtUtils::MakeMaker;

##----------------------------------------------------------------------
## Configuration
##----------------------------------------------------------------------
use Alien::Gfsm;
use Alien::GfsmXL;
my %prereq = (
	      'ExtUtils::MakeMaker' => 6.52, ##-- for CONFIGURE_REQUIRES
	      'Alien::Gfsm' => 0.001,
	      'Alien::GfsmXL' => 0.001,
	      'Gfsm' => 0.0404,
	     );

##-- ensure minimum libgfsmxl version
use version;
my $gfsmxl_min_version   = "0.0.11";
if (Alien::GfsmXL->install_type ne 'system') {
  my $gfsmxl_alien_version = (Alien::GfsmXL->can('pkgconfig')
			      ? Alien::GfsmXL->pkgconfig('gfsmxl')->keyword('Version') ##-- RT bug #124235 with Alien::Base v0.41
			    : (Alien::GfsmXL->can('config')
			       ? Alien::GfsmXL->config('version')			 ##-- Alien::Base >= v0.41
			       : undef));
  die("Failed to determine \$gfsmxl_alien_version") if (!defined($gfsmxl_alien_version));

  (my $v_alien = $gfsmxl_alien_version) =~ s/\-/_/g;
  die("Required library libgfsmxl >= v$gfsmxl_min_version not found; we have v$gfsmxl_alien_version\n")
    if (version->parse($v_alien) < version->parse($gfsmxl_min_version));
}
elsif (system("pkg-config --atleast-version=${gfsmxl_min_version} gfsmxl") != 0) {
  die("Required library libgfsmxl >= v$gfsmxl_min_version not found; we have v", `pkg-config --modversion gfsmxl`);
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
WriteMakefile
  (
   NAME		=> 'Gfsm::XL',
   #DISTNAME	=> 'gfsmxl-perl',
   DISTNAME	=> 'Gfsm-XL',
   AUTHOR       => 'Bryan Jurish <moocow@cpan.org>',
   ABSTRACT	=> 'Perl interface to libgfsmxl finite-state cascade library',
   VERSION_FROM	=> 'XL.pm',
   LICENSE => 'perl',

   ##-- prerequisites
   CONFIGURE_REQUIRES => \%prereq,
   PREREQ_PM => \%prereq,

   ##-- user variables
   #CC           => 'c++',   ##-- your c++ compiler
   LIBS         => join(' ', Alien::Gfsm->libs,   Alien::GfsmXL->libs),      ##-- additional libraries
   INC          => join(' ', Alien::Gfsm->cflags, Alien::GfsmXL->cflags),    ##-- additional includes
   DEFINE       => '-DHAVE_CONFIG_H',	     ##-- additional defines
   CCFLAGS      => '',                        ##-- additional flags
   OBJECT       => 'XL.o GfsmXLPerl.o',
   OPTIMIZE     => '-O2 -pipe',

   ##-- scripts
   EXE_FILES => [glob('gfsmxl*.perl')],

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
		 ."XL.c: "
		 .(''
		   ." Cascade.xs"
		   ." Lookup.xs"
		   ." XL.xs"
		  )
		 ."\n\n"
		 ##-- c->o dependencies
		 ."XL.o: XL.c GfsmXLPerl.h\n"
		 ."\n"
		 ."GfsmXLPerl.o: GfsmXLPerl.h GfsmXLPerl.c\n"
		 ."\n"
		 ###-- readme
		 ."dist: README.txt\n"
		 ."\n"
		 ."create_distdir: README.txt\n"
		 #."distdir_am: README.txt\n"
		 ."\n"
		 ."distcheck: README.txt\n"
		 ."\n"
		 ."manicheck: README.txt\n"
		 ."\n"
		 ## -- more here
		 ."\n"
		);
  $inherited;
}

##---------------------------------------------------------------
sub MY::special_targets {
  package MY;
  my $inherited = shift->SUPER::special_targets(@_);
  $inherited .=
"
.SUFFIXES: .pm .pod .rpod .man .txt .html

##-- pod2xxx
.pm.html:
\tpod2html --title=\$@ --infile=\$< --outfile=\$@

.pm.txt:
\tpod2text \$< \$@

.pod.html:
\tpod2html --title=\$@ --infile=\$< --outfile=\$@

.pod.txt:
\tpod2text \$< \$@

##-- readme
.rpod.html:
\tpod2html --title=\$@ --infile=\$< --outfile=\$@

.rpod.txt:
\tpod2text \$< \$@

readme: README.txt

";
  return $inherited;
}
