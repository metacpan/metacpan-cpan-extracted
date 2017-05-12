use inc::Module::Install;

name 'MIME-Lite-TT-HTML-Japanese';
all_from 'lib/MIME/Lite/TT/HTML/Japanese.pm';

requires 'MIME::Lite';
requires 'Template';
requires 'Jcode';
requires 'DateTime::Format::Mail';

test_requires 'Test::More';

auto_include;

WriteAll;
