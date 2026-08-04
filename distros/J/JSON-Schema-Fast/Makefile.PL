use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# Probe whether the C compiler accepts a flag (compile-only). Conservative:
# any failure -> "no", so a smoker with a fussy toolchain still builds.
sub can_ccflag {
    my ($flag) = @_;
    return 0 unless eval { require ExtUtils::CBuilder; 1 };
    return 0 unless eval { require File::Temp; 1 };
    my $ok = eval {
        my $cb  = ExtUtils::CBuilder->new(quiet => 1);
        my $dir = File::Temp::tempdir(CLEANUP => 1);
        my $src = "$dir/probe.c";
        open my $fh, '>', $src or die;
        print {$fh} "int main(void){return 0;}\n";
        close $fh;
        my $obj = $cb->compile(source => $src, extra_compiler_flags => [$flag]);
        unlink $obj if $obj && -e $obj;
        1;
    };
    return $ok ? 1 : 0;
}

# -O3 always; -flto only when the compiler clearly accepts it (opt out with
# JSF_NO_LTO=1 for toolchains where LTO links are flaky).
my $optimize = '-O3';
if (!$ENV{JSF_NO_LTO} && can_ccflag('-flto')) {
    $optimize .= ' -flto';
}

my %WriteMakefileArgs = (
    NAME             => 'JSON::Schema::Fast',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/JSON/Schema/Fast.pm',
    ABSTRACT_FROM    => 'lib/JSON/Schema/Fast.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',

    # C core lives under include/; Fast.xs is the thin SV<->C marshalling layer.
    INC              => '-Iinclude',
    OBJECT           => 'Fast$(OBJ_EXT)',
    XS               => { 'Fast.xs' => 'Fast.c' },
    OPTIMIZE         => $optimize,

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        # JSON::Schema::Modern is an OPTIONAL conformance oracle (phase 05);
        # tests skip cleanly when it is absent, so it is not required here.
    },
    PREREQ_PM => {
        # Used from phase 02 onward (JSON-text schema input) and phase 04+.
        'File::Raw::JSON' => '0',
        'Object::Proto'   => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'JSON-Schema-Fast-* Fast.c Fast$(OBJ_EXT) Fast.bs' },
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
