use 5.034000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $github    = 'https://github.com/E7-87-83/Math-Cryptarithm';

WriteMakefile(
    NAME              => 'Math::Cryptarithm',
    VERSION_FROM      => 'lib/Math/Cryptarithm.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    'PREREQ_PM'       => {
                            'Algorithm::Permute' => '0.16'
                         },
    ABSTRACT_FROM     => 'lib/Math/Cryptarithm.pm', # retrieve abstract from module
    AUTHOR            => 'e78783 <e78783@tqgtyn10aqxuxoi0mkfbldi5vh.jx.internal.cloudapp.net>',
    LICENSE           => 'perl',
    'TEST_REQUIRES'   => {
                            'Test::More' => '1.00',
                         },
    'META_MERGE' => {
            resources => {
                    repository => {
                            type => 'git',
                            url  => "$github.git",
                            web  => $github,
                            },
                    bugtracker => {
                            web    => "$github/issues",
                            },
                    homepage => $github,
                    },
            },
);
