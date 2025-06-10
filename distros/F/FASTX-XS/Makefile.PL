use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Check for zlib
my $zlib_found = 0;
my @check_paths = (
    '/opt/homebrew',
    '/usr/local', 
    '/usr',
    '/System/Volumes/Data/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk/usr',
    '/System/Volumes/Data/Library/Developer/CommandLineTools/SDKs/MacOSX14.5.sdk/usr'
);

foreach my $path (@check_paths) {
    if (-f "$path/include/zlib.h") {
        $zlib_found = 1;
        last;
    }
}

if (!$zlib_found) {
    warn "Warning: zlib headers not found. You need to install zlib development files.\n";
    warn "For Debian/Ubuntu: sudo apt-get install zlib1g-dev\n";
    warn "For CentOS/RHEL: sudo yum install zlib-devel\n";
    warn "For macOS: brew install zlib\n";
    exit 0;
}


# Define the MakeMaker arguments
WriteMakefile(
    NAME             => 'FASTX::XS',
    AUTHOR           => 'Andrea Telatin <proch@cpan.org>',
    VERSION_FROM     => 'lib/FASTX/XS.pm',
    ABSTRACT_FROM    => 'lib/FASTX/XS.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    # Repository and issue tracking
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
            homepage => 'https://github.com/quadram-institute-bioscience/fastx-xs',
        },
    },
    
    # Prerequisites
    PREREQ_PM         => {
        'XSLoader' => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        'FASTX::Reader' => '0',
    },
    PREREQ_PM => {
        'strict'   => '0',
        'warnings' => '0',
    },
    LIBS => ['-lz'],
    INC => '-I.',
    XS => {'FASTX.xs' => 'FASTX.c'},
    OBJECT => '$(O_FILES)',
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'FASTX-XS-*' },
    # Optional: Specify no index for certain files
    no_index => {
            directory => ['t', 'xt', 'examples', 'demo'],
            file      => ['demo.pl', 'demo_pp.pl'],
    },
);
