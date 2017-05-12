#!perl -T

use Test::More tests => 5;

use File::TTX;

# Test loading and header read access using one of our test files.
$ttx = File::TTX->load('t/01-test1.ttx');
isa_ok($ttx, 'File::TTX');
isa_ok($ttx->{toolsettings}, 'XML::Snap');

# Toolsettings
is ($ttx->CreationDate(), '20100701T231801Z');
is ($ttx->CreationTool(), 'SDL TRADOS TagEditor');
is ($ttx->CreationToolVersion(), '8.3.0.863');