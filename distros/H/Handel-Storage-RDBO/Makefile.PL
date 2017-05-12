# $Id$
use strict;
use warnings;
use inc::Module::Install 0.65;

name 'Handel-Storage-RDBO';
license 'perl';
perl_version '5.008001';
all_from 'lib/Handel/Storage/RDBO.pm';

requires 'Clone'            => '0.31';
requires 'Handel'           => '1.00013';
requires 'Rose::DB'         => '0.762';
requires 'Rose::DB::Object' => '0.789';
requires 'Rose::Object'     => '0.858';
requires 'Scalar::Util';


build_requires 'Directory::Scratch';

tests 't/*.t t/*/*.t';
clean_files 't/var Handel-Storage-RDBO-*';

eval {
    system 'pod2text lib/Handel/Storage/RDBO.pm > README';
};

auto_install;
WriteAll;
