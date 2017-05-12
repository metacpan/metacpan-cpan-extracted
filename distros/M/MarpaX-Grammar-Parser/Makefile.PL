use ExtUtils::MakeMaker;

use inc::Module::Install;

# -----------------------------------------------

name 'MarpaX-Grammar-Parser';

license 'artistic_2';

perl_version '5.014000';

all_from 'lib/MarpaX/Grammar/Parser.pm';

install_share;

repository 'https://github.com/ronsavage/MarpaX-Grammar-Parser';

requires 'charnames'        => 0;
requires 'Data::TreeDumper' => 0.40;
requires 'English'          => 1.04;
requires 'Getopt::Long'     => 2.41;
requires 'File::ShareDir'   => 1.03;
requires 'File::Slurp'      => 9999.19;
requires 'File::Temp'       => 0.2301;
requires 'Log::Handler'     => 0.78;
requires 'List::AllUtils'   => 0.08;
requires 'Marpa::R2'        => 2.096000;
requires 'Moo'              => 1.002000;
requires 'open'             => 0;
requires 'Path::Tiny'       => 0.025;
requires 'perl'             => '5.14.2'; # For the utf8 stuff.
requires 'Pod::Usage'       => 1.36;
requires 'Tree::DAG_Node'   => 1.24;
requires 'strict'           => 0;
requires 'Types::Standard'  => 1.000004;
requires 'utf8'             => 0;
requires 'warnings'         => 0;

test_requires 'Test::More' => 0.98;
#test_requires 'Test::Pod'  => 1.45; # Make it optional. See t/pod.t

recursive_author_tests('xt');

WriteAll;
