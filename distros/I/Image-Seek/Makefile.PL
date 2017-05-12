use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use ExtUtils::CppGuess;

my $guess = ExtUtils::CppGuess->new;

WriteMakefile(
    NAME              => 'Image::Seek',
    AUTHOR			  => 'Helmut Wollmersdorfer <helmut.wollmersdorfer@gmail.com>',
    ABSTRACT_FROM     => 'lib/Image/Seek.pm',
    VERSION_FROM      => 'lib/Image/Seek.pm', # finds $VERSION
    MIN_PERL_VERSION  => '5.6.0',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1

    $guess->makemaker_options,

    TEST_REQUIRES		=> {
            'Test::Exception' => '0',
            'Test::More' => '0.88',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        license  => [ 'gpl_1' ],
        prereqs => {
  			runtime => {
    			requires => {
      				'perl'          => '5.006',
    			},
    			recommends => {
    			},
    			suggests => {
    			},
  			},
 			build => {
    			requires => {
    			    'ExtUtils::MakeMaker' => '0',
      				'ExtUtils::CppGuess' => '0.11',
    			},
  			},
  			configure => {
         		requires => {
            		'ExtUtils::MakeMaker' => '0',
            		'ExtUtils::CppGuess' => '0.11',
         		}
      		},
  			test => {
    			requires => {
      				'Test::Exception' => '0',
            		'Test::More' 	  => '0.88',
    			},
  			}
		},
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/wollmers/Image-Seek.git',
                web  => 'https://github.com/wollmers/Image-Seek',
            },
            homepage => 'https://github.com/wollmers/Image-Seek',
            bugtracker => {
                web => 'https://github.com/wollmers/Image-Seek/issues',
            },
        },
     },
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
	NAME         => 'Image::Seek',
	NAMES        => \@names,
	DEFAULT_TYPE => 'IV',
	C_FILE       => 'const-c.inc',
	XS_FILE      => 'const-xs.inc',
  );

}
else {
  use File::Copy;
  use File::Spec;
  for my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
