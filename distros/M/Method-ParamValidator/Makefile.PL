#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Method::ParamValidator',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Method/ParamValidator.pm',
    ABSTRACT_FROM      => 'lib/Method/ParamValidator.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'JSON'                 => 0,
        'Moo'                  => '2.000000',
        'Moo::Role'            => '2.000000',
        'namespace::autoclean' => '0.28',
        'Type::Tiny'           => 0,
        'Throwable'            => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Method-ParamValidator-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Method::ParamValidator'                       => { file => 'lib/Method/ParamValidator.pm',                    version => '0.12' },
            'Method::ParamValidator::Key::Method'          => { file => 'lib/Method/ParamValidator/Key/Method.pm',         version => '0.12' },
            'Method::ParamValidator::Key::Field'           => { file => 'lib/Method/ParamValidator/Key/Field.pm',          version => '0.12' },
            'Method::ParamValidator::Key::Field::DataType' => { file => 'lib/Method/ParamValidator/Key/Field/DataType.pm', version => '0.12' },
            'Method::ParamValidator::Exception'            => { file => 'lib/Method/ParamValidator/Exception.pm',          version => '0.12' },
            'Method::ParamValidator::Exception::InvalidMethodName'              => { file => 'lib/Method/ParamValidator/Exception/InvalidMethodName.pm',              version => '0.12' },
            'Method::ParamValidator::Exception::MissingParameters'              => { file => 'lib/Method/ParamValidator/Exception/MissingParameters.pm',              version => '0.12' },
            'Method::ParamValidator::Exception::InvalidParameterDataStructure'  => { file => 'lib/Method/ParamValidator/Exception/InvalidParameterDataStructure.pm',  version => '0.12' },
            'Method::ParamValidator::Exception::MissingRequiredParameter'       => { file => 'lib/Method/ParamValidator/Exception/MissingRequiredParameter.pm',       version => '0.12' },
            'Method::ParamValidator::Exception::MissingMethodName'              => { file => 'lib/Method/ParamValidator/Exception/MissingMethodName.pm',              version => '0.12' },
            'Method::ParamValidator::Exception::MissingFieldName'               => { file => 'lib/Method/ParamValidator/Exception/MissingFieldName.pm',               version => '0.12' },
            'Method::ParamValidator::Exception::UndefinedRequiredParameter'     => { file => 'lib/Method/ParamValidator/Exception/UndefinedRequiredParameter.pm',     version => '0.12' },
            'Method::ParamValidator::Exception::FailedParameterCheckConstraint' => { file => 'lib/Method/ParamValidator/Exception/FailedParameterCheckConstraint.pm', version => '0.12' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Method-ParamValidator.git',
                web  => 'https://github.com/manwar/Method-ParamValidator',
            },
        }})
     : ()
    ),
);
