use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec::Functions 'abs2rel';
use Devel::CallParser 'callparser1_h', 'callparser_linkable';

# Resolve Object::Proto include directory:
#   1. Try installed Object::Proto module (CPAN / system)
#   2. Fall back to sibling directory (development)
my $proto_inc;
eval {
    no warnings 'redefine';
    local *XSLoader::load = sub {};  # skip XS bootstrap
    require Object::Proto;
    my $dir = Object::Proto->include_dir();
    $proto_inc = $dir if $dir && -d $dir;
};
if (!$proto_inc && -d '../Object-Proto/include') {
    $proto_inc = '../Object-Proto/include';
}
die "Cannot find Object::Proto include directory.\n"
  . "Install Object::Proto or place it as a sibling directory.\n"
    unless $proto_inc;

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
    XSMULTI => 1,
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'Devel::CallParser'  => '0.002',
        'Object::Proto'      => '0.12',
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Devel::CallParser'  => '0.002',
        'Devel::CallChecker'  => '0.009',
        'Object::Proto'      => '0.12',
    },
    TYPEMAPS         => [],
    INC              => "-I. -I$proto_inc",
    ($#linkable >= 0 ? (OBJECT => join(' ', @linkable)) : ()),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Enum-Declare-* callparser1.h' },
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
