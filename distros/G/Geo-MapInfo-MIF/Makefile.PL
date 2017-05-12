use inc::Module::Install::DSL 0.91;

all_from      	lib/Geo/MapInfo/MIF.pm
requires        Text::CSV 1.12
requires        File::Slurp 9999.13
requires        Params::Util 1.00
requires        File::Basename 2.76
test_requires 	Test::More  0.42
test_requires   File::Spec 0.80