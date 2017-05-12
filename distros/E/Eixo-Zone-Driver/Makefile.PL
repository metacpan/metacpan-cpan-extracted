use 5.018002;
use ExtUtils::MakeMaker;

unless($^O =~ /linux/i){
	die "Not in linux " . uname();
}

my $kernel_version = `uname -r`;

my ($major, $minor) = $kernel_version =~ /^(\d+)\.(\d+)/;

unless($major >= 3 && $minor >= 12){

	die("Needs >= 3.12 kernel version");
}


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(

    NAME              => 'Eixo::Zone::Driver',

    VERSION_FROM      => 'lib/Eixo/Zone/Driver.pm', # finds $VERSION

    PREREQ_PM         => {


		"Devel::AssertOS" => 0,	

		"Devel::CheckLib" => 0,

	

	}, # e.g., Module::Name => 1.1


    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005

      (ABSTRACT_FROM  => 'lib/Eixo/Zone/Driver.pm', # retrieve abstract from module

       AUTHOR         => 'frmadem <frmadem@cpan.org>') : ()),

    	DEFINE            => '', # e.g., '-DHAVE_SOMETHING'

    	INC               => '-I.', # e.g., '-I. -I/usr/include/other'

    	LIBS              => ['-lcap'],
	
);
