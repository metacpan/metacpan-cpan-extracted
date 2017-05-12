use inc::Module::Install;

name           'Devel-CompiledCalls';
all_from       'lib/Devel/CompiledCalls.pm';

# Not sure about the exact versions, but these
# are the ones I have and they work
requires       'B::CallChecker'  => '0.000';
requires       'B::Compiling'    => '0.02';
requires       'Sub::Identify'   => '0.04';

# T::B::T before 0.09 breaks with modern perls
build_requires 'Test::Builder::Tester' => 0.09;

license 'perl';
githubmeta;
author_tests('xt');

WriteAll;
