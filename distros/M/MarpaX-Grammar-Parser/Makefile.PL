use ExtUtils::MakeMaker;

use inc::Module::Install;

# -----------------------------------------------

name 'MarpaX-Grammar-Parser';

license 'perl';

perl_version '5.014000';

all_from 'lib/MarpaX/Grammar/Parser.pm';

install_share;

repository 'https://github.com/ronsavage/MarpaX-Grammar-Parser';

requires 'Data::RenderAsTree'	=> 1.01;
requires 'English'				=> 1.04;
requires 'Getopt::Long'			=> 2.41;
requires 'File::Basename'		=> 0;
requires 'File::ShareDir'		=> 1.03;
requires 'File::Slurper'		=> 0.008;
requires 'File::Spec'			=> 0;
requires 'File::Temp'			=> 0.2301;
requires 'lib'					=> 0;
requires 'Log::Handler'			=> 0.78;
requires 'List::AllUtils'		=> 0.08;
requires 'Marpa::R2'			=> 2.096000;
requires 'Moo'					=> 1.002000;
requires 'Path::Tiny'			=> 0.025;
requires 'perl'					=> '5.14.2'; # For the utf8 stuff.
requires 'Pod::Usage'			=> 1.36;
requires 'Set::Array'			=> 0.30;
requires 'Tree::DAG_Node'		=> 1.24;
requires 'strict'				=> 0;
requires 'Types::Standard'		=> 1.000004;
requires 'warnings'				=> 0;

test_requires 'Test2::Bundle::Extended'	=> '0.000030';;
test_requires 'Test::More'				=> 0.98;
#test_requires 'Test::Pod'				=> 1.45; # Make it optional. See xt/author/pod.t

tests_recursive('xt');

WriteAll;
