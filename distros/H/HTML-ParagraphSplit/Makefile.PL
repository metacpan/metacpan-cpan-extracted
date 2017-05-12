use inc::Module::Install;

name     'HTML-ParagraphSplit';
all_from 'lib/HTML/ParagraphSplit.pm';
license  'perl';

requires 'HTML::Entities';
requires 'HTML::TreeBuilder';
requires 'HTML::Tagset';
requires 'Module::CoreList';

recommends 'Test::Pod';
recommends 'Test::Pod::Coverage';

auto_install;
WriteAll;
