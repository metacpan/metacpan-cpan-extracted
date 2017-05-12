use inc::Module::Install;

name           'Math-Symbolic-Custom-LaTeXDumper';
all_from       'lib/Math/Symbolic/Custom/LaTeXDumper.pm';
requires       'Math::Symbolic' => '0.509';

build_requires 'Test::More'              => '0.47';

WriteAll();
