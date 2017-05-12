use inc::Module::Install;

name 'HTML-TurboForm';
all_from 'lib/HTML/TurboForm.pm';

requires 'YAML::Syck';
requires 'Email::Valid';
requires 'UNIVERSAL::require';
requires 'Date::Calc';
requires 'Imager';

install_script glob('script/*.pl');
auto_install;
WriteAll;
