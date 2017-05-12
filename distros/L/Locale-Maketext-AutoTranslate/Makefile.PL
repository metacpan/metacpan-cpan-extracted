use inc::Module::Install;

name        'Locale-Maketext-AutoTranslate';
all_from    'lib/Locale/Maketext/AutoTranslate.pm';

requires    'Moose' => '0';
requires    'REST::Google::Translate' => '0';
requires    'Locale::Maketext::Extract' => '0';
requires    'HTML::Entities' => '0';
requires    'Locale::Maketext::Lexicon' => '0';

install_script glob('bin/*.pl');
auto_install;
WriteAll;
