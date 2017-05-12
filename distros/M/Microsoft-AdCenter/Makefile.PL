#!/usr/local/bin/perl
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Microsoft::AdCenter',
    AUTHOR        => 'Xerxes Tsang',
    VERSION_FROM  => 'lib/Microsoft/AdCenter.pm',
    ABSTRACT_FROM => 'lib/Microsoft/AdCenter.pm',
    LICENSE       => 'artistic',
    PREREQ_PM     => {
    	'Class::Accessor::Chained'  => 0,
        'Crypt::SSLeay'             => 0,
        'Data::Dumper'              => 0,
        'DateTime::Format::ISO8601' => 0,
        'DateTime::Format::W3CDTF'  => 0,
        'Scalar::Util'              => 0,
        'SOAP::Lite'                => 0.71,
        'Test::Class'               => 0,
        'Test::More'                => 0
    },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean         => { FILES => 'Microsoft-AdCenter-*' },
);
