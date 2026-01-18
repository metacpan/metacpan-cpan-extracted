use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;
use Cwd qw(abs_path);
use Config;

my $base_dir = abs_path('.');

# Detect platform
my $is_macos = $^O eq 'darwin';
my $is_linux = $^O eq 'linux';

# Use Alien::ggml for ggml dependency
my ($inc_dir, $lib_flags, $rpath);

eval {
    require Alien::ggml;
    $inc_dir = Alien::ggml->cflags;
    $lib_flags = Alien::ggml->libs;
    
    my $lib_path = File::Spec->catdir(Alien::ggml->dist_dir, 'lib');
    
    # Detect available GPU backends
    if ($is_macos) {
        # Metal backend on macOS
        my $metal_lib = File::Spec->catfile($lib_path, 'libggml-metal.dylib');
        if (-f $metal_lib) {
            $lib_flags .= ' -lggml-metal';
            print "  Metal GPU backend: enabled\n";
        }
    } elsif ($is_linux) {
        # CUDA backend (NVIDIA GPUs)
        my $cuda_lib = File::Spec->catfile($lib_path, 'libggml-cuda.so');
        if (-f $cuda_lib) {
            $lib_flags .= ' -lggml-cuda';
            print "  CUDA GPU backend: enabled\n";
        }
        
        # Vulkan backend (cross-platform GPU)
        my $vulkan_lib = File::Spec->catfile($lib_path, 'libggml-vulkan.so');
        if (-f $vulkan_lib) {
            $lib_flags .= ' -lggml-vulkan';
            print "  Vulkan GPU backend: enabled\n";
        }
        
        # SYCL backend (Intel GPUs)
        my $sycl_lib = File::Spec->catfile($lib_path, 'libggml-sycl.so');
        if (-f $sycl_lib) {
            $lib_flags .= ' -lggml-sycl';
            print "  SYCL GPU backend: enabled\n";
        }
        
        # HIP/ROCm backend (AMD GPUs)
        my $hip_lib = File::Spec->catfile($lib_path, 'libggml-hip.so');
        if (-f $hip_lib) {
            $lib_flags .= ' -lggml-hip';
            print "  HIP/ROCm GPU backend: enabled\n";
        }
        
        # BLAS backend (CPU acceleration)
        my $blas_lib = File::Spec->catfile($lib_path, 'libggml-blas.so');
        if (-f $blas_lib) {
            $lib_flags .= ' -lggml-blas';
            print "  BLAS CPU backend: enabled\n";
        }
    } elsif ($^O eq 'MSWin32' || $^O eq 'cygwin') {
        # Windows backends
        my $cuda_lib = File::Spec->catfile($lib_path, 'ggml-cuda.dll');
        if (-f $cuda_lib) {
            $lib_flags .= ' -lggml-cuda';
            print "  CUDA GPU backend: enabled\n";
        }
        
        my $vulkan_lib = File::Spec->catfile($lib_path, 'ggml-vulkan.dll');
        if (-f $vulkan_lib) {
            $lib_flags .= ' -lggml-vulkan';
            print "  Vulkan GPU backend: enabled\n";
        }
    }
    
    # Get rpath for dynamic libraries
    my @dynlibs = Alien::ggml->dynamic_libs;
    if (@dynlibs && Alien::ggml->install_type eq 'share') {
        $rpath = $is_macos ? "-Wl,-rpath,$lib_path" : "-Wl,-rpath,$lib_path";
    }
    print "Using Alien::ggml (install type: ", Alien::ggml->install_type, ")\n";
    print "  cflags: $inc_dir\n";
    print "  libs: $lib_flags\n";
    1;
} or do {
    die <<"END_ERROR";
Alien::ggml is required to build Lugh.

Please install it first:
    cpanm Alien::ggml

Or from source:
    git clone https://github.com/lnation/Alien-ggml
    cd Alien-ggml
    perl Makefile.PL && make && make install

END_ERROR
};

# Platform-specific flags
my $ccflags = '-Wall';
my $cc = $Config{cc};
my $ld = $Config{ld};

if ($is_macos) {
    $cc = 'clang' unless $cc =~ /clang/;
    $ld = 'clang' unless $ld =~ /clang/;
}

my %WriteMakefileArgs = (
    NAME             => 'Lugh',
    AUTHOR           => ['lnation <email@lnation.org>'],
    VERSION_FROM     => 'lib/Lugh.pm',
    ABSTRACT_FROM    => 'lib/Lugh.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    XSMULTI          => 1,
    INC              => $inc_dir,
    LIBS             => [$lib_flags],
    CC               => $cc,
    LD               => $ld,
    CCFLAGS          => $ccflags,
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    ($rpath ? (dynamic_lib => { OTHERLDFLAGS => $rpath }) : ()),
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.12',
        'Alien::ggml'         => '0.01',
    },
    BUILD_REQUIRES => {
        'Alien::ggml' => '0.01',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.96',
    },
    PREREQ_PM => {
        'Alien::ggml' => '0.01',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/lnation/Lugh.git',
                web  => 'https://github.com/lnation/Lugh',
            },
            bugtracker => {
                web => 'https://github.com/lnation/Lugh/issues',
            },
        },
        prereqs => {
            runtime => {
                recommends => {
                    'threads' => 0,
                },
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Lugh-* lib/*.o lib/*.c lib/*.bs blib' },
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
delete $WriteMakefileArgs{META_MERGE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 };

WriteMakefile(%WriteMakefileArgs);

