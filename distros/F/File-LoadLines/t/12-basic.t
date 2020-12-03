#! perl

# Test parameter types.

use strict;
use warnings;
use Test::Exception tests => 2;

use utf8;
use File::LoadLines;

throws_ok { loadlines() } qr/Missing filename/, 'caught missing file';
throws_ok { loadlines('dummy.txt', []) } qr/Invalid options/, 'caught invalid options';
