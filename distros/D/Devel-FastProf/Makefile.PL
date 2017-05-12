
# use 5.008001;

use ExtUtils::MakeMaker;

use Config;

my $define = '';
my %prereq;

if ($Config::Config{d_gettimeod}) {
    $define = '-DHAS_GETTIMEOD';
}
else {
    $prereq{'Time::HiRes'} = '1.74';
}

WriteMakefile( NAME => 'Devel::FastProf',
	       VERSION_FROM => 'lib/Devel/FastProf.pm',
	       PREREQ_PM => { %prereq,
			      Sort::Key => '1.01' },
	       ABSTRACT_FROM => 'lib/Devel/FastProf.pm',
	       AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',
               # OPTIMIZE => '-O0 -g',
               # OPTIMIZE => '-O3',
               DEFINE => $define,
	       EXE_FILES => [ 'bin/fprofpp' ],
	       MAN1PODS => { 'bin/fprofpp' => '$(INST_MAN1DIR)/fprofpp.1' } );
