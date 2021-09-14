use v5.14.0;
use Devel::CheckBin;
check_bin('git');
if ($^O =~ m/mswin32/i) {
    print STDERR "NA: Not yet tested on Windows\n";
    exit 0;
}

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME         => 'Devel::Git::MultiBisect',
    VERSION_FROM => 'lib/Devel/Git/MultiBisect.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Study build or test output over a range of git commits',
    MIN_PERL_VERSION => '5.14.0',
    LICENSE      => 'perl_5',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Devel::CheckBin' => 0,
    },
    PREREQ_PM    => {
        'Carp' => 0,
        'Cwd' => 0,
        'Data::Dumper' => 0,
        'Digest::MD5' => 0,
        'ExtUtils::MakeMaker' => 0,
        'File::Copy' => 0,
        'File::Spec' => 0,
        'File::Temp' => 0,
        'Getopt::Long' => 0,
        'List::Util' => 0,
        'strict' => 0,
        'warnings' => 0,
    },
    TEST_REQUIRES => {
        'Test::Simple' => 0.44,
        'Capture::Tiny' => 0,
        'Data::Dump' => 0,
        'Data::Dumper' => 0,
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
        repository  => {
          url  => 'https://github.com/jkeenan/devel-git-multibisect.git',
          web  => 'https://github.com/jkeenan/devel-git-multibisect',
          type => 'git',
        },
      },
    }) : () ),
);

my %FallbackPrereqs = (
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{$WriteMakefileArgs{TEST_REQUIRES}},
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
