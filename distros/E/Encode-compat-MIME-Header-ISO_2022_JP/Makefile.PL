use inc::Module::Install;

name('Encode-compat-MIME-Header-ISO_2022_JP');
author('Kazuho Oku');
version_from('lib/Encode/compat/MIME/Header/ISO_2022_JP.pm');
abstract_from('lib/Encode/compat/MIME/Header/ISO_2022_JP.pm');
license('perl');

auto_include;
auto_install;

WriteAll;
