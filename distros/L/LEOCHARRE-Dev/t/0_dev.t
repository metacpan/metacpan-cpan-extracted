use Test::Simple 'no_plan';
use strict;
use lib './lib';
use LEOCHARRE::Dev ':all';
# use Smart::Comments '###';

`mkdir -p t/Temp-Dist/lib/Temp/Dist
touch t/Temp-Dist/Makefile.PL
touch t/Temp-Dist/MANIFEST
touch t/Temp-Dist/lib/Temp/Dist.pm
touch t/Temp-Dist/lib/Temp/Example.pm
touch t/Temp-Dist/lib/Temp/Dist/File.pm
touch t/Temp-Dist/lib/Temp/Dist/Agro.pm
`;
ok( -f 't/Temp-Dist/Makefile.PL' ) or die;

ok( my $absd = is_pmdist('./t/Temp-Dist') );
ok( -d $absd,"got $absd");

ok( ! is_pmdist('./t/ataeetawtaeta'));

my @ls = ls_pmdist('./t/Temp-Dist');
### @ls
ok(  scalar @ls,"ls dist [@ls]");

my $distname = pmdist_guess_name('./t/Temp-Dist');
ok( $distname eq 'Temp::Dist', "got distname $distname" );

my $verfrom = pmdist_guess_version_from('./t/Temp-Dist');
ok($verfrom eq 'lib/Temp/Dist.pm', "got verfrom $verfrom");


