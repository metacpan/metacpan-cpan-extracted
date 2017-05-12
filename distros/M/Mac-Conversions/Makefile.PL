use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
unless ($^O eq "MacOS") {
	print "This is currently useful only under MacPerl\n";
	exit(0);
}
WriteMakefile(
    'NAME'	=> 'Mac::Conversions',
    'VERSION_FROM' => 'Conversions.pm', # finds $VERSION
    'PREREQ_PM' => {'Convert::BinHex' => 0},
);
