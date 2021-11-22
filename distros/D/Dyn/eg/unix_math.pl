use strict;
use warnings;
use lib '../lib', '../blib/arch', '../blib/lib';
use Dyn qw[:dc :dl :sugar];
use File::Find;
$|++;
#
my @files;
find(
    {   preprocess => sub {
            my $depth = $File::Find::dir =~ tr[/][];
            $depth > 2 ? () : @_;
        },
        wanted => sub {
            push @files, $File::Find::name
                if ( -f $File::Find::name and /libm(-[\d\.]+)?\.so(?:\.\d)?/ );
        }
    },
    '/usr/lib'
);
my ($path) = @files;                 # pick one
my $lib    = dlLoadLibrary($path);
my $init   = dlSymsInit($path);
#
CORE::say "Symbols in libm ($path): " . dlSymsCount($init);
CORE::say 'All symbol names in libm:';
CORE::say sprintf '  %4d %s', $_, dlSymsName( $init, $_ ) for 0 .. dlSymsCount($init) - 1;
CORE::say 'libm has sqrtf()? ' .       ( dlFindSymbol( $lib, 'sqrtf' )       ? 'yes' : 'no' );
CORE::say 'libm has pow()? ' .         ( dlFindSymbol( $lib, 'pow' )         ? 'yes' : 'no' );
CORE::say 'libm has not_in_libm()? ' . ( dlFindSymbol( $lib, 'not_in_libm' ) ? 'yes' : 'no' );
#
CORE::say 'sqrtf(36.f) = ' . call( $lib, 'sqrtf', 'f)f', 36.0 );
CORE::say 'pow(2.0, 10.0) = ' . call( $lib, 'pow', 'dd)d', 2.0, 10.0 );
