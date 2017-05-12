use strict;
use lib '.';
use inc::Module::Install;
use FindBin qw($Bin);

# module metadata
name 'File-BSED';
license 'perl';
all_from 'lib/File/BSED.pm';

# Compiling.
my @CC_FILES = qw(
    libgbsed.c
    BSED.c
);

my $CC_OPTIMIZE_FLAGS = "-O";

# Dependencies
my %REQUIRES = (
    'Getopt::LL' => 0,
    'File::Temp' => 0,
);

my %BUILD_REQUIRES = (
    'ExtUtils::ParseXS'   => 0,
    'Test::More'          => 0,
);

# for META.yml, CPAN etc.
my @NO_INDEX_DIRS = qw(
    inc
    t
    devel
);

# Programs to install.
my @PROGRAMS = qw(
    bin/plbsed
);

# ----------------------------------------------------------- #
my $libgbsed_include = $ENV{LIBBSED_INCLUDE};
if (! $libgbsed_include) {
    $libgbsed_include = $Bin;
}

cc_inc_paths(join q{ }, $libgbsed_include, '-DHAVE_CONFIG_H=1');
cc_files(@CC_FILES);
#cc_optimizer_flags($CC_OPTIMIZE_FLAGS);


for my $no_index_dir (@NO_INDEX_DIRS) {
    no_index(directory => $no_index_dir);
}


while (my ($req_mod, $req_version) = each %REQUIRES) {
    requires($req_mod => $req_version);
}

while (my ($req_mod, $req_version) = each %BUILD_REQUIRES) {
    requires($req_mod => $req_version);
}

for my $program (@PROGRAMS) {
    install_script $program;
}

# Write Makefile
can_cc() or die "This module requires a C compiler";
sign();
WriteAll();
