use inc::Module::Install;

name 'Iterator-Merger';
all_from 'lib/Iterator/Merger.pm';

build_requires 'Test::More' => '0.42';

requires 'Array::Heap' => 0;
# recommends 'Array::Heap' => 0;

WriteAll;