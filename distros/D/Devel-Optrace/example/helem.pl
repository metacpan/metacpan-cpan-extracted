#!perl -w
use strict;

use Devel::Optrace -all;

local %^H;
$^H{foo} = 0xFF;
