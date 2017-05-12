# use ExtUtils::MakeMaker;
use inc::Module::Install;

license				'perl';
build_requires		'Test::More'	=> '0.42';
no_index			'directory'		=> 'examples';
perl_version		'5.006';

WriteMakefile(
    'NAME'			=> 'Math::RandomOrg',
    'AUTHOR'		=> 'Gregory Todd Williams <gwilliams@cpan.org>',
    'ABSTRACT'		=> 'Retrieve random numbers and data from the random.org webservice.',
    'VERSION_FROM'	=> 'lib/Math/RandomOrg.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    					'LWP'			=> 0,
    					'Math::BigInt'	=> 0,
    				}
);

