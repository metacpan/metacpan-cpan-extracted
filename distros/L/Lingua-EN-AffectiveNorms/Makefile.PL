use inc::Module::Install;

name     'Lingua-EN-AffectiveNorms';
all_from 'lib/Lingua/EN/AffectiveNorms.pm';
author   'Kieren Diment <zarquon@cpan.org>';
license  'perl';

build_requires 'Test::More';
requires 'DBIx::Class::Schema::Loader';
auto_install;
install_share;
WriteAll;

