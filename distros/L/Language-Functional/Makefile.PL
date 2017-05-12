#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Language::Functional',
    'VERSION_FROM' => 'Functional.pm',
    'LICENSE'      => 'perl',
    'AUTHOR'       => 'Leon Brocard <acme@astray.com>',
    'ABSTRACT'     => 'a module which makes Perl slightly more functional',
    'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
