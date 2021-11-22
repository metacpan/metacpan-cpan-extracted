use strict;
use warnings;
use lib '../lib', '../blib/arch', '../blib/lib';
use Dyn qw[:dc :dl :sugar];
$|++;
#
my $path = 'C:\Windows\System32\user32.dll';
my $lib  = dlLoadLibrary($path);
#
CORE::say 'width = ' . call( $lib, 'GetSystemMetrics', 'i)i', 0 );
CORE::say 'height = ' . call( $lib, 'GetSystemMetrics', 'i)i', 1 );
CORE::say 'number of monitors = ' . call( $lib, 'GetSystemMetrics', 'i)i', 80 );
