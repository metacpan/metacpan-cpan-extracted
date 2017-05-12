use ExtUtils::MakeMaker;
#$Verbose = 1;
use ExtUtils::Embed;
my $CFLAGS = ccopts();
chomp($CFLAGS);

$ENV{'CFLAGS'} = $CFLAGS." -DHAVE_CONFIG_H";

WriteMakefile(
     NAME   => 'libbc',
     SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
     clean  => {'FILES' => 'libbc$(LIBEEXT)'},
     INC => "-I./",
             );

sub MY::top_targets {
  my $section = <<EOS;
MYLIBS = execute.o \\
	bc.o \\
	global.o \\
	storage.o \\
	load.o \\
	scan.o \\
	myutil1.o \\
	myutil2.o \\
	getopt.o \\
	getopt1.o \\
	vfprintf.o \\
	number.o

all :: static

pure_all :: static

static ::       libbc\$(LIB_EXT)

libbc\$(LIB_EXT): \$(MYLIBS)
	\$(AR) cr libbc\$(LIB_EXT) \$(MYLIBS)
	\$(RANLIB) libbc\$(LIB_EXT)

EOS

  return $section;
}

