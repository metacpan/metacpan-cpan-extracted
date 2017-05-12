use strict;
use inc::Module::Install;

name           'File-Tasks';
all_from       'lib/File/Tasks.pm';
requires       'Clone'            => '0.21';
requires       'File::Find::Rule' => '0.20';
requires       'File::Flat'       => '0.92';
requires       'File::Spec'       => '0.80';
requires       'List::Util'       => '1.15';
requires       'Scalar::Util'     => '1.15';
requires       'Archive::Builder' => '1.04';
requires       'Params::Coerce'   => '0.05';
requires       'Params::Util'     => '0.06';
build_requires 'Test::More'       => '0.47';
build_requires 'Class::Inspector' => '1.11'; # Needed by Test::ClassAPI
build_requires 'Test::ClassAPI'   => '1.02';
include        'Test::ClassAPI';

WriteAll;
