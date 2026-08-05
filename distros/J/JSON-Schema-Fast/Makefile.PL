use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();
use Config;

# JSON::Schema::Fast is a PROVIDER (it installs jsf_abi.h so consumers such as
# Open::API reach its C ABI through ExtUtils::Depends, no vendored copy) AND a
# CONSUMER of Fetch's and File::Raw::JSON's C ABIs (fetch_abi.h / frj_abi.h).
# Fall back to sibling dirs when the consumed providers are not yet installed.
my ($DEP_INC, %DEP);
{
    my $dep;
    if (eval { $dep = ExtUtils::Depends->new(
                   'JSON::Schema::Fast', 'Fetch', 'File::Raw::JSON'); 1 } && $dep) {
        # consumer include paths come from the installed providers below
    } else {
        die "JSON::Schema::Fast needs Fetch 0.08+ and File::Raw::JSON 0.05+ "
          . "installed,\nor present as sibling directories (../Fetch, "
          . "../File-Raw-JSON).\n"
            unless -d '../Fetch/include/fetch' && -d '../File-Raw-JSON/include';
        $dep = ExtUtils::Depends->new('JSON::Schema::Fast');   # provider only
        $DEP_INC = '-I../Fetch/include/fetch -I../File-Raw-JSON/include';
    }
    $dep->install('include/jsf_abi.h');                # provide jsf_abi.h
    mkdir 'Install' unless -d 'Install';
    $dep->save_config('Install/Files.pm');
    %DEP = $dep->get_makefile_vars;
    $DEP_INC = join ' ', grep { defined && length } $DEP_INC, delete $DEP{INC};
    delete $DEP{LDFROM};        # keep MakeMaker's default $(OBJECT)
    delete $DEP{LIBS};          # jsf links no C libraries of its own
    # EU::Depends' PM map (installing jsf_abi.h + Files.pm) replaces MakeMaker's
    # auto-detected PM, so re-add the module's own .pm files.
    File::Find::find(sub {
        return unless /\.pm\z/;
        (my $rel = $File::Find::name) =~ s{^lib/}{};
        $DEP{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
    }, 'lib');
}

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
    # DEP_INC adds Fetch's + File::Raw::JSON's ABI headers (ExtUtils::Depends).
    INC              => "-Iinclude $DEP_INC",
    OBJECT           => 'Fast$(OBJ_EXT)',
    XS               => { 'Fast.xs' => 'Fast.c' },
    OPTIMIZE         => $optimize,

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'Fetch'               => '0.08',
        'File::Raw::JSON'     => '0.05',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        # JSON::Schema::Modern is an OPTIONAL conformance oracle (phase 05);
        # tests skip cleanly when it is absent, so it is not required here.
    },
    PREREQ_PM => {
        'File::Raw::JSON' => '0.05',  # JSON decode via its C ABI (frj_abi.h)
        'Object::Proto'   => '0',
        'Fetch'           => '0.08',  # remote $ref fetch + its C ABI (fetch_abi.h)
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'JSON-Schema-Fast-* Fast.c Fast$(OBJ_EXT) Fast.bs '
                      . 'Install/Files.pm' },
    %DEP,   # ExtUtils::Depends: installs jsf_abi.h + Files.pm, TYPEMAPS, our PM
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
