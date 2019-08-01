use ExtUtils::MakeMaker;

my $pkg = 'IO::FDpassData';
$pkg =~ /[^:]+$/;
my $module = $& .'.pm';
my $cfile = $& .'.c';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %makeparms = (
    NAME		=> $pkg,
    VERSION_FROM	=> $module, # finds $VERSION
#    depend		=> {'FDpassData.c' => $depends }, 
    PREREQ_PM		=> {
#
			},
# LIBS list should be a single string to be compatible with script below
#    LIBS		=> '-L/usr/local/lib',
#    INC			=> '-I/usr/local/include',
    clean		=> { FILES    => "*~ tmp* *.o *.a *.bs *.A  configure.ac configure"},
    realclean		=> { FILES    => "configure.ac configure aclocal.m4 autom4te.cache config.guess config.* depcomp missing compile install-sh stamp-h1 libtool ltmain.sh Makefile.in m4/* Makefile"},
#    OBJECT		=> 'FDpassData.o',
    dist		=> {COMPRESS=>'gzip', SUFFIX=>'gz'},
#    CCFLAGS		=> '-fPIC'
#    LDDLFLAGS		=> '-no-pie'
);

###################################

sub MY::top_targets {
  package MY;
  my $inherited = shift->SUPER::top_targets(@_);
  $inherited =~ s/(pure_all\s+::.+)/$1 README/;
  $inherited;
}

sub MY::post_constants {
  my $post_constants = $Config{scriptdirexp} .'/pod2text';
  if (-e $post_constants) {
    $post_constants = q|
MY_POD2TEXT = |. $post_constants .q|
|;
  } else {   
    $post_constants = q|
MY_POD2TEXT = echo "perl distro missing 'pod2text' to convert " |;
  }
}

sub MY::postamble {
  package MY;
  my $postamble = q|
README  : |. $module .q|
	@$(MY_POD2TEXT) |. $module .q| > README

|;
}

WriteMakefile(%makeparms);
1;
