use inc::Module::Install;

all_from 'lib/JS/Test/Base.pod';

requires 'JS' => '0.17';
requires 'JS::Test::Simple' => '0.28';

clean_files 'META.yml';

WriteAll;

