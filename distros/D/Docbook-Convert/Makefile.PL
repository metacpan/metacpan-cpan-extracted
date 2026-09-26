use 5.010;
use strict;
use warnings;
use version;

use ExtUtils::MakeMaker;

eval {
    require ASPEER::MakeMaker::Markdown::Pod;
    ASPEER::MakeMaker::Markdown::Pod->import();
    1;
};

my $mm_ver=$ExtUtils::MakeMaker::VERSION;
if ($mm_ver=~/_/) {
    $mm_ver=eval($mm_ver);
    die $@ if $@;
}
my %WriteMakefile=(
    NAME             => 'Docbook::Convert',
    DISTNAME         => 'Docbook-Convert',
    VERSION_FROM     => 'lib/Docbook/Convert.pm',
    ABSTRACT_FROM    => 'lib/Docbook/Convert.pm',
    EXE_FILES        => [
        'bin/docbook-convert',
        'bin/docbook2md'
    ],
    LICENSE          => 'perl',
    AUTHOR           => 'Andrew Speer <andrew.speer@isolutions.com.au>',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM        => {
        'Carp'           => 0,
        'Cwd'            => 0,
        'Data::Dumper'   => 0,
        'File::Basename' => 0,
        'File::Find'     => 0,
        'File::Spec'     => 0,
        'File::Temp'     => 0,
        'FindBin'        => 0,
        'Getopt::Long'   => 0,
        'HTML::Entities' => 0,
        'IO::File'       => 0,
        'IPC::Run3'      => 0,
        'Pod::Usage'     => 0,
        'Text::Table'    => 0,
        'Text::Wrap'     => 0,
        'XML::Twig'      => '3.40',
        'base'           => 0,
        'strict'         => 0,
        'vars'           => 0,
        'warnings'       => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'version'             => 0,
    },
    TEST_REQUIRES => {
        'Digest::MD5' => 0,
        'File::Path'  => 0,
        'File::Temp'  => 0,
        'Test::More'  => 0,
    },
    META_MERGE => {
        x_authority => 'cpan:ASPEER',
        'meta-spec' => {version => 2},
        prereqs     => {
            configure => {
                suggests => {
                    'ASPEER::MakeMaker::Markdown::Pod' => '1.010',
                },
            },
            runtime => {
                suggests => {
                    'Image::Magick'  => 0,
                    'LWP::UserAgent' => 0,
                },
            },
        },
        resources   => {
            bugtracker => {
                web => 'https://github.com/aspeer/pm-Docbook-Convert/issues',
            },
            homepage   => 'https://github.com/aspeer/pm-Docbook-Convert',
            repository => {
                type => 'git',
                url  => 'https://github.com/aspeer/pm-Docbook-Convert.git',
                web  => 'https://github.com/aspeer/pm-Docbook-Convert',
            },
        },
    },
    depend => {Makefile => '$(VERSION_FROM)'},
    dist   => {COMPRESS => 'gzip -9f', SUFFIX => '.gz'},
);
my %MM_Compat=(
    '6.31' => [qw(LICENSE)],
    '6.46' => [qw(META_MERGE)],
    '6.48' => [qw(MIN_PERL_VERSION)],
    '6.52' => [qw(CONFIGURE_REQUIRES)],
    '6.64' => [qw(TEST_REQUIRES)],
);
while (my ($mm_ver_test, $name_ar)=each(%MM_Compat)) {
    if (version->parse($mm_ver) < version->parse($mm_ver_test)) {
        delete(@WriteMakefile{@{$name_ar}});
    }
}
WriteMakefile(%WriteMakefile);
package MY;
sub post_initialize {


    #  Add license file, other support files here
    #
    my $self=shift();
    $self->{'PM'}{'LICENSE'}='$(INST_LIBDIR)/$(BASEEXT)/LICENSE';
    return $self->SUPER::post_initialize;

}
