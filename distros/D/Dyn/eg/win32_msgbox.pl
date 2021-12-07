use strict;
use warnings;
use lib '../lib', '../blib/arch', '../blib/lib';
use Dyn qw[:dc :dl :sugar];
$|++;
#
my $path = 'C:\Windows\System32\user32.dll';
my $lib  = dlLoadLibrary($path);
my $init = dlSymsInit($path);
#
CORE::say "Symbols in user32 ($path): " . dlSymsCount($init);
CORE::say 'All symbol names in user32:';
CORE::say sprintf '  %4d %s', $_, dlSymsName( $init, $_ ) for 0 .. dlSymsCount($init) - 1;
CORE::say 'user32 has MessageBoxA()? ' . ( dlFindSymbol( $lib, 'MessageBoxA' ) ? 'yes' : 'no' );
CORE::say 'user32 has NonExistant()? ' . ( dlFindSymbol( $lib, 'NonExistant' ) ? 'yes' : 'no' );
#
CORE::say 'MessageBoxA(...) = ' .
    Dyn::load( $lib, 'MessageBoxA', '(IZZI)i' )->call( 0, 'JAPH!', 'Hello, World', 0 );
