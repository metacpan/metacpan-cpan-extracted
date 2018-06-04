# $Id: Makefile.PL,v 1.6 2008/03/04 21:49:19 drhyde Exp $

use 5.00405;
use ExtUtils::MakeMaker;

use strict;
$^W = 1;

WriteMakefile1(
    NAME         => 'Devel::CheckLib',
    ABSTRACT_FROM => 'lib/Devel/CheckLib.pm',
    VERSION_FROM => 'lib/Devel/CheckLib.pm',
    AUTHOR => [
        'David Cantrell',
        'David Golden',
        'Yasuhiro Matsumoto',
    ],
    PREREQ_PM    => {
        'File::Temp'        => 0.16,
        'Exporter'          => 0,
        'File::Spec'        => 0,
    },
    MIN_PERL_VERSION => '5.00405',
    META_MERGE => {
        dynamic_config => 0,
        resources => {
            repository => 'http://github.com/mattn/p5-Devel-CheckLib',
        },
    },
    TEST_REQUIRES => {
        'Test::More'        => 0.62,  # too high? but API changed here
        'IO::CaptureOutput' => 1.0801,
        'Mock::Config'      => 0.02,
    },
    LICENSE => 'perl',
    EXE_FILES    => [qw(
        bin/use-devel-checklib
    )],
);

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 2. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
    }
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;

    WriteMakefile(%params);
}

