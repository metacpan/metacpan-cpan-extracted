#use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $KPLUSHOME3 = $ENV{'KPLUSHOME3'};
if ("$KPLUSHOME3" eq "") {
    die "KPLUSHOME3 must be set to Kondor+ installation directory.\n";
}

my $EFFIXARCH = $ENV{'EFFIXARCH'};
if ("$EFFIXARCH" eq "") {
    die "EFFIXARCH must be set to Kondor+ system architecture.\n";
}


WriteMakefile(
    NAME              => 'Kools::Okapi',
    VERSION_FROM      => 'lib/Kools/Okapi.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Kools/Okapi.pm', # retrieve abstract from module
       AUTHOR         => 'Gabriel Galibourg <>') : ()),
    LIBS              => ["-L${KPLUSHOME3}/api/lib/${EFFIXARCH} -lOKAPI -lOKAPICOMPRESS -lsocket -lnsl"],
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. -I${KPLUSHOME3}/api/include/OKAPI",
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);




#WriteMakefile(
#    'NAME'	=> 'Kools::Okapi',
#    'VERSION_FROM' => 'Okapi.pm', # finds $VERSION
#    'INC'	=> "-I${KPLUSHOME3}/api/include/OKAPI",
#    'DEFINE'	=> $define,
#
#);
