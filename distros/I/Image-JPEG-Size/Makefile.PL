#! perl

use 5.010001;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use Devel::CheckLib;

my @dirs = qw(
    /usr/local
    /opt/local
);

my @libs = map "$_/lib", @dirs;
my @incs = map "$_/include", @dirs;

check_lib_or_exit(
    lib     => 'jpeg',
    header  => [qw(stddef.h stdio.h jpeglib.h)],
    libpath => [@libs],
    incpath => [@incs],
);

my $module_file = 'lib/Image/JPEG/Size.pm';
my %make = (
    NAME => 'Image::JPEG::Size',
    AUTHOR => 'Robert Rothenberg <rrwo@cpan.org>',
    ABSTRACT_FROM => $module_file,
    VERSION_FROM => $module_file,
    OBJECT => 'Size.o',
    CONFIGURE_REQUIRES => {
        'Devel::CheckLib' => 0,
    },
    PREREQ_PM => {
        'XSLoader' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::Fatal' => 0,
    },
    INC  =>  join(' ', (map "-I$_", @incs)),
    LIBS => [join ' ', (map "-L$_", @libs), "-ljpeg"],
    META_MERGE => {
        resources => {
            repository => 'git://github.com/robrwo/image-jpeg-size.git',
            bugtracker => 'https://github.com/robrwo/image-jpeg-size/issues',
        },
    },
);

my $eumm_version = eval $ExtUtils::MakeMaker::VERSION;
if ($eumm_version < 6.64) {
    my ($prereq, $test_req) = ($make{PREREQ_PM}, delete $make{TEST_REQUIRES});
    %$prereq = (%$prereq, %$test_req);
}

WriteMakefile(%make);
