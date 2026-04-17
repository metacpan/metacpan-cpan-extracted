use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Spec::Functions 'abs2rel';
use Devel::CallParser 'callparser1_h', 'callparser_linkable';

# ExtUtils::Depends handles include paths automatically.
# Object::Proto uses dl_load_flags {0x01} (RTLD_GLOBAL) so its symbols
# are visible to downstream XS modules at runtime.
my $pkg;
eval { $pkg = ExtUtils::Depends->new('Enum::Declare', 'Object::Proto') };
if (!$pkg) {
    # Development fallback: sibling Object-Proto directory
    die "Cannot find Object::Proto dependency.\n"
      . "Install Object::Proto or place it as a sibling directory.\n"
        unless -d '../Object-Proto/include';
    $pkg = ExtUtils::Depends->new('Enum::Declare');
    $pkg->set_inc('-I. -I../Object-Proto/include');
} else {
    my %vars = $pkg->get_makefile_vars;
    $pkg->set_inc('-I. ' . ($vars{INC} || ''));
}

# Generate callparser1.h for this perl
open my $fh, '>', 'callparser1.h' or die "Couldn't write to callparser1.h: $!";
$fh->print(callparser1_h);
close $fh;

my @linkable = map { abs2rel($_) } callparser_linkable;
unshift @linkable, '$(BASEEXT)$(OBJ_EXT)' if @linkable;

my %WriteMakefileArgs = (
    NAME             => 'Enum::Declare',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Enum/Declare.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.014',
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'Devel::CallParser'  => '0.004',
        'Object::Proto'      => '0.15',
     	'ExtUtils::Depends'  => '0',
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Devel::CallParser'  => '0.003',
        'Devel::CallChecker'  => '0.009',
        'Object::Proto'      => '0.14',
    },
    TYPEMAPS         => [],
    ($#linkable >= 0 ? (OBJECT => join(' ', @linkable)) : ()),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Enum-Declare-* callparser1.h' },
    $pkg->get_makefile_vars,
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
