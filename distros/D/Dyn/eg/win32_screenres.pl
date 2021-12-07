use strict;
use warnings;
use lib '../lib', '../blib/arch', '../blib/lib';
use Dyn qw[:dc :dl :sugar];
$|++;
#
sub GetSystemMetrics : Dyn('C:\Windows\System32\user32.dll', '(i)i');
#
CORE::say 'width = ' . GetSystemMetrics(0);
CORE::say 'height = ' . GetSystemMetrics(1);
CORE::say 'number of monitors = ' . GetSystemMetrics(80);
