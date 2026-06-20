use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

my $pkg = ExtUtils::Depends->new('Destructure::Declare');
$pkg->set_inc('-I. -Iinclude');
$pkg->install('include/destructure.h');

mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');
my %dep_vars = $pkg->get_makefile_vars;

$dep_vars{PM}{'lib/Destructure/Declare.pm'} = '$(INST_LIB)/Destructure/Declare.pm';

my %WriteMakefileArgs = (
    NAME             => 'Destructure::Declare',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Destructure/Declare.pm',
    ABSTRACT_FROM    => 'lib/Destructure/Declare.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.014',
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Destructure-Declare-* Install/Files.pm' },
    %dep_vars,
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
