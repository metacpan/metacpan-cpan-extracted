use integer;
use strict;
use warnings;
BEGIN { unshift @INC, 'lib', 'testlib' }
use PtsTestLib;

PtsTestLib::test_mod('MIME::AltWords');
