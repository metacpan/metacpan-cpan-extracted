use inc::Module::Install;

all_from 'lib/JS/Test/Simple.pod';

requires 'JS' => '0.15';

clean_files 'META.yml';

WriteAll;

