use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.006;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %BuildReqs = (
    "ExtUtils::MakeMaker" => 0,
);
my %ConfigReqs = (
    "ExtUtils::MakeMaker" => 0,
);
my %DevReqs = (
    "Test::Pod" => 0,
    "Test::Pod::Coverage" => 0,
    "Test::Spelling" => 0,
    "Test::Version" => 0,
);
my %TestReqs = (
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0,
    "Carp" => 0,
    'Exporter' => '5.57',
    'Fcntl' => 0,
    "File::Basename" => 0,
    "File::Spec" => '3.01',
    "File::Temp" => 0,
    "IO::Handle" => 0,
    "POSIX" => 0,
    "Scalar::Util" => '1.00', # had tainted()
    "Socket" => 0,
    "Symbol" => 0,
    "Test::More" => 0,
);
my %prereqs = (
    'B' => 0,
    'Carp' => 0,
    'Exporter' => '5.57',
    'Errno' => 0,
    'Fcntl' => 0,
    "File::Basename" => 0,
    "File::Spec" => '3.01',
    "File::Temp" => 0,
    "IO::Handle" => 0,
    'POSIX' => 0,
    "strict" => 0,
    "warnings" => 0,
);

my %WriteMakefileArgs = (
    'NAME' => 'File::Slurp',
    "DISTNAME" => "File-Slurp",
    'LICENSE' => 'perl_5',
    'AUTHOR' => 'Uri Guttman <uri@stemsystems.com>',
    'VERSION_FROM' => 'lib/File/Slurp.pm',
    'ABSTRACT_FROM' => 'lib/File/Slurp.pm',
    'META_MERGE' => {
        'dynamic_config' => 0,
        'meta-spec' => {version => 2},
        'no_index' => {directory => ['xt']},
        'resources' => {
            repository => {
                type => 'git',
                url  => 'https://github.com/perhunter/slurp.git',
                web  => 'https://github.com/perhunter/slurp',
            },
        },
        'x_contributors' => [
            'Aristotle Pagaltzis <ARISTOTLE@cpan.org>',
            'Chase Whitener <capoeirab@cpan.org>',
            'Dan Book <grinnz@gmail.com>',
            'Graham Knop <haarg@haarg.org>',
            'James E Keenan <jkeenan@cpan.org>',
        ],
    },
    "BUILD_REQUIRES" => \%BuildReqs,
    "CONFIGURE_REQUIRES" => \%ConfigReqs,
    "TEST_REQUIRES" => \%TestReqs,
    "PREREQ_PM" => \%prereqs,
    "test" => {
        "TESTS" => "t/*.t",
    },
);

unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
    my %fallback = (%prereqs, %TestReqs, %BuildReqs);
    delete $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{BUILD_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%fallback;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION('6.52') };

delete $WriteMakefileArgs{META_MERGE}
  unless eval { ExtUtils::MakeMaker->VERSION('6.46') };

delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION('6.31') };

WriteMakefile(%WriteMakefileArgs);
