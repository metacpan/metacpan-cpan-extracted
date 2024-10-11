#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More tests => 6;

use_ok('File::ValueFile');
ok((scalar(eval {File::ValueFile->known(':all'     )}) || 0) >  0, 'known(:all) returns objects');
ok((scalar(eval {File::ValueFile->known(':BADCLASS')}) || 0) == 0, 'known(:BADCLASS) returns no objects');

isa_ok((File::ValueFile->known(':all', as => 'Data::Identifier'))[0], 'Data::Identifier', 'known(:all) asked for Data::Identifier');
ok(defined((File::ValueFile->known(':all', as => 'ise'))[0]), 'known(:all) can return ise (defined)');
is(ref((File::ValueFile->known(':all', as => 'ise'))[0]), '', 'known(:all) can return ise (no-ref)');

exit 0;
