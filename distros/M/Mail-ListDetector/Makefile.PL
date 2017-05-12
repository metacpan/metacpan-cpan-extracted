use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'Mail::ListDetector',
    'VERSION_FROM'  => 'lib/Mail/ListDetector.pm', # finds $VERSION
    'PREREQ_PM'     => {
                        'Carp'            	=> 0,
                        'Email::Abstract'	=> 3.001,
                        'Email::Valid'    	=> 0.182,
                        'URI'             	=> 1.10,
                        'Test::More'      	=> 0.08,
			'Mail::Internet'	=> 2.04,
                       }, 
    'dist' => { 'COMPRESS' => 'gzip -9f',
                'SUFFIX'   => 'gz',
    },
    'AUTHOR'        => 'Michael Stevens <michael@etla.org>',
    'ABSTRACT'      => 'Mailing list message detector',
    'LICENSE'	    => 'perl',
);
