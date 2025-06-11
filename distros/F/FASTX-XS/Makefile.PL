use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Detect zlib more robustly
my $zlib_found = 0;
my ($inc_flags, $lib_flags) = ('', '-lz');

# Try standard locations
my @check_paths = qw(/usr/local /usr /opt/local);
foreach my $path (@check_paths) {
    if (-f "$path/include/zlib.h") {
        $inc_flags = "-I$path/include" if $path ne '/usr';
        $lib_flags = "-L$path/lib -lz" if $path ne '/usr';
        $zlib_found = 1;
        last;
    }
}

# Final check - try compile test
if (!$zlib_found) {
    warn "zlib headers not found in standard locations\n";
    warn "Trying system default...\n";
    # Let it try anyway - system might have zlib in default paths
}

WriteMakefile(
    NAME             => 'FASTX::XS',
    AUTHOR           => 'Andrea Telatin <proch@cpan.org>',
    VERSION_FROM     => 'lib/FASTX/XS.pm',
    ABSTRACT_FROM    => 'lib/FASTX/XS.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        'FASTX::Reader' => '0',
    },
    PREREQ_PM => {
        'XSLoader' => 0,
        'strict'   => 0,
        'warnings' => 0,
    },
    
    # XS Configuration
    LIBS   => [$lib_flags],
    INC    => "$inc_flags -I.",
    XS     => {'FASTX.xs' => 'FASTX.c'},
    OBJECT => '$(O_FILES)',
    
    # Metadata
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/quadram-institute-bioscience/fastx-xs.git',
                web  => 'https://github.com/quadram-institute-bioscience/fastx-xs',
            },
            bugtracker => {
                web => 'https://github.com/quadram-institute-bioscience/fastx-xs/issues',
            },
        },
    },
    
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'FASTX-XS-*' },
);