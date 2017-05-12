use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Image/PNG/FileConvert.pm';
my $pod = 'lib/Image/PNG/FileConvert.pod';
my $repo = 'https://github.com/benkasminbullock/Image-PNG-FileConvert';

WriteMakefile (
    NAME => 'Image::PNG::FileConvert',
    # Where to get the module's version information
    VERSION_FROM => $pm,
    # Where the file abstract is.
    ABSTRACT_FROM => $pod,
    # Modules which this depends on
    PREREQ_PM => {
        'Image::PNG::Libpng' => '0.27',
    },
    # Executable files (scripts) to be installed
    EXE_FILES => [
        'script/file2png',
        'script/png2file',
    ],
    LICENSE => 'perl',
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        }
    },    
    # There is no requirement as far as I know, but Image::PNG::Libpng
    # has this.
    MIN_PERL_VERSION => '5.008001',
);

