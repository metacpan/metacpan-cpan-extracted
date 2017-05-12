# -*- perl -*-

use Test::More tests => 4;

BEGIN { use_ok( 'File::Find::Random' ); }
BEGIN { use_ok( 'Cwd' ); }

use strict;
use File::Spec::Functions;
my $orig_cwd = cwd();
chdir('t') if(-d 't');

mkdir('testdir2');

eval {
     File::Find::Random->find('testdir2');
};
isa_ok($@, 'Error::File::Find::Random',"Exception object should be returned");
is($@,"Cannot find a file in this pass at 'testdir2'\n",'And the text is correct');
rmdir('testdir2');

chdir($orig_cwd);