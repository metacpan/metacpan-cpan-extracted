#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
        'ExtUtils::Manifest'    => 1.58,
    };

my $prereq_pm = {
        'mod_perl2'             => 2.00,
        'Apache::DBI'           => 1.11,
        'CGI'                   => 4.00,
        'Class::C3::Adopt::NEXT'=> 0.14,
        'Config::General'       => 2.50,
        'CTK'                   => 2.00,
        'Data::Dumper'          => 2.00,
        'DBI'                   => 1.636,
        'Digest::MD5'           => 2.36,
        'Encode'                => 2.72,
        'File::Copy'            => 2.09,
        'File::Copy::Recursive' => 0.38,
        'File::Find'            => 0,
        'File::Spec'            => 3.60,
        'File::Temp'            => 0.22,
        'JSON::XS'              => 3.00,
        'MIME::Base64'          => 3.00,
        'Perl::OSType'          => 1.00,
        'Sys::Hostname'         => 0,
        'Time::HiRes'           => 1.90,
        'Template'              => 2.24,
        'Term::ANSIColor'       => 4.00,
        'Text::SimpleTable'     => 2.03,
        'Try::Tiny'             => 0.07,
        'URI'                   => 1.50,
        'YAML::XS'              => 0.40,
    };

my $exefiles = [qw(
        bin/mpminus
    )];

WriteMakefile(
    'NAME'                  => 'MPMinus',
    'MIN_PERL_VERSION'      => 5.016001,
    'VERSION_FROM'          => 'lib/MPMinus.pm',
    'ABSTRACT_FROM'         => 'lib/MPMinus.pm',
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'EXE_FILES'             => $exefiles,
    'AUTHOR'                => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'               => 'perl',
    'META_MERGE' => { "meta-spec" => { version => 2 },
        recommends => {
            'DBI'           => 0,
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'http://www.serzik.com',
            repository      => 'http://svn.serzik.com/MPMinus/trunk',
            license         => 'https://dev.perl.org/licenses',
        },
    },
);

1;
