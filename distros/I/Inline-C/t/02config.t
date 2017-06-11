use strict; use warnings; use diagnostics;
use FindBin '$Bin';
use lib $Bin;
use Test::More;
use TestInlineSetup;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

eval 'use Inline C => "void foo(){}", FOO => "Bar";';
like($@, qr/not a valid config option/, 'bogus config options croak');

use Inline C => 'char* XYZ_Howdy(){return "Hello There";}', PREFIX => 'XYZ_';
is(Howdy, "Hello There", 'PREFIX config option');

done_testing;
