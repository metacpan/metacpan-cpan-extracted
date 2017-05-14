#! /usr/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
        'NAME' => 'Math::Expr',
        'DISTNAME' => 'Math-Expr',
        'VERSION' => '0.4',
        'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'}
);
