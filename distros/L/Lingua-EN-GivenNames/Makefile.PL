use ExtUtils::MakeMaker;

use inc::Module::Install;

# -----------------------------------------------

name 'Lingua-EN-GivenNames';

license 'artistic_2';

perl_version '5.014000';

all_from 'lib/Lingua/EN/GivenNames.pm';

install_share;

repository 'https://github.com/ronsavage/Lingua-EN-GivenNames';

requires 'Config::Tiny' => 2.14;
requires 'DBI' => 1.622;
requires 'DBIx::Admin::CreateTable' => 2.07;
requires 'DBIx::Table2Hash' => 1.17;
requires 'Data::Dumper::Concise' => 2.020;
requires 'ExtUtils::MakeMaker' => 6.62;
requires 'feature' => 1.20;
requires 'File::ShareDir' => 1.03;
requires 'File::Slurp' => 9999.19;
requires 'File::Spec' => 3.33;
requires 'Getopt::Long' => 2.38;
requires 'HTML::HTML5::Entities' => 0.003;
requires 'HTML::TreeBuilder' => 4.2;
requires 'HTTP::Tiny' => 0.022;
requires 'Lingua::EN::StopWordList' => 1.00;
requires 'List::Compare' => 0.37;
requires 'Moo' => 2.000001;
requires 'open' => 1.08;
requires 'parent' => 0.225;
requires 'Pod::Usage' => 1.51;
requires 'strict' => 0.00;
requires 'Test::More' => 1.001014;
requires 'Test::Pod' => 1.48;
requires 'Text::CSV' => 1.21;
requires 'Text::CSV::Slurp' => 1;
requires 'Text::Xslate' => 1.5015;
requires 'Types::Standard' => 1.000005;
requires 'Unicode::CaseFold' => 0.02;
requires 'warnings' => 0.00;

test_requires 'Test::More' => 0.98;
#test_requires 'Test::Pod'  => 1.45; # Make it optional. See t/pod.t

tests_recursive('xt');

WriteAll;
