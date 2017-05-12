use ExtUtils::MakeMaker;

use inc::Module::Install;

# -----------------------------------------------

name 'MarpaX-Grammar-GraphViz2';

license 'perl';

perl_version '5.014000';

all_from 'lib/MarpaX/Grammar/GraphViz2.pm';

install_share;

repository 'https://github.com/ronsavage/MarpaX-Grammar-GraphViz2';

requires 'charnames'               => 1.18;
requires 'Config'                  => undef;
requires 'Config::Tiny'            => 2.15;
requires 'Date::Simple'            => 3.03;
requires 'Getopt::Long'            => 2.41;
requires 'File::Basename'          => 2.82;
requires 'File::HomeDir'           => 1.00;
requires 'File::ShareDir'          => 1.03;
requires 'File::Slurp'             => 9999.19;
requires 'File::Spec'              => 3.40;
requires 'File::Temp'              => 0.2301;
requires 'File::Which'             => 1.09;
requires 'GraphViz2'               => 2.19;
requires 'HTML::Entities::Interpolate' => 1.05;
requires 'List::AllUtils'          => 0.03;
requires 'Log::Handler'            => 0.78;
requires 'MarpaX::Grammar::Parser' => 2.00;
requires 'Moo'                     => 1.002000;
requires 'open'                    => 0;
requires 'Path::Tiny'              => 0.025;
requires 'perl'                    => '5.14.2'; # For the utf8 stuff.
requires 'Pod::Usage'              => 1.36;
requires 'strict'                  => 0;
requires 'Text::Xslate'            => 1.6002;
requires 'utf8'                    => 0;
requires 'warnings'                => 0;

test_requires 'Test::More' => 0.98;
#test_requires 'Test::Pod'  => 1.45; # Make it optional. See t/pod.t

recursive_author_tests('xt');

WriteAll;
