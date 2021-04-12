#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2021, Roland van Ipenburg
use strict;
use warnings;
use utf8;
use 5.014000;
use Module::Build;

our $VERSION = 'v1.0.3';

my $class = Module::Build->subclass( 'code' => <<'END_SUBCLASS' );

    sub _extra_author_actions {
        my ($self) = @_;
        $ENV{'AUTHOR_TESTING'} = 1;
        $self->depends_on('clean');
        $self->depends_on('build');
        if (!$ENV{'RELEASE_TESTING'}) {
            $self->depends_on('distmeta');
        }
        $self->test_files( qw< t xt/author > );
        $self->recursive_test_files(1);
    }

    sub ACTION_test {
        my ($self) = @_;
        if ($ENV{'AUTHOR_TESTING'}) {
            $self->_extra_author_actions();
        }
        return $self->SUPER::ACTION_test(@_);
    }

    sub ACTION_clean {
        my ($self) = @_;
        $self->add_to_cleanup(
            $self->dist_dir,
            $self->dist_dir . q{.tar.gz},
        );
        return $self->SUPER::ACTION_clean(@_);
    }

    sub ACTION_authortest {
        my ($self) = @_;
        $self->_extra_author_actions();
        $self->depends_on('test');
        return;
    }

    sub ACTION_disttest {
        my ($self) = @_;
        $ENV{'RELEASE_TESTING'} = 1;
        $ENV{'TEST_SIGNATURE'} = 1;
        return $self->SUPER::ACTION_disttest(@_);
    }

END_SUBCLASS

my %CONFIG = (
    'module_name' => 'Geo::METAR::Deduced',
    'license'     => 'perl',
    'dist_author' => 'Roland van Ipenburg <roland@rolandvanipenburg.com>',
    'requires'    => {
        'Class::Measure::Scientific::FX_992vb' => 0,
        'English'                              => 0,
        'Geo::ICAO'                            => 0,
        'Geo::METAR'                           => 0,
        'Moose'                                => 0,
        'MooseX::NonMoose'                     => 0,
        'Readonly'                             => 1.03,
        'Set::Scalar'                          => 0,
        'perl'                                 => '5.16.0',
        'strict'                               => 0,
        'utf8'                                 => 0,
        'warnings'                             => 0,
    },
    'configure_requires' => { 'Module::Build' => 0.40, },
    'build_requires'     => {
        'Module::Build'     => 0.40,
        'Module::Signature' => 0.22,
        'Test::More'        => 0.86,
        'Test::Signature'   => 1.04,
    },
    'test_requires' => {
        'Test::More'       => 0.86,
        'Test::NoWarnings' => 0,
    },
    'meta_merge' => {
        'resources' => {
            'repository' =>
              'https://bitbucket.org/rolandvanipenburg/geo-metar-deduced',
            'bugtracker' =>
'https://bitbucket.org/rolandvanipenburg/geo-metar-deduced/issues',
        },
    },
    'sign' => 1,
);

if ( $ENV{'AUTHOR_TESTING'} || $ENV{'RELEASE_TESTING'} ) {
    my %AUTHOR_TEST_REQUIRES = (
        'Devel::Cover'               => 0,
        'ExtUtils::Manifest'         => 0,
        'File::Basename'             => 0,
        'File::Spec'                 => 0,
        'Perl::Critic::Bangs'        => 0,
        'Perl::Critic::StricterSubs' => 0,
        'Test::Kwalitee'             => 0,
        'Test::Perl::Critic'         => 0,
        'Test::Pod'                  => 0,
        'Test::Pod::Coverage'        => 0,
        'Test::Requires'             => 0,
        'Test::Spelling'             => 0,
        'Test::TestCoverage'         => 0,
    );
    while ( my ( $k, $v ) = each %AUTHOR_TEST_REQUIRES ) {
        $CONFIG{'test_requires'}{$k} = $v;
    }
}
$class->new(%CONFIG)->create_build_script;
