use inc::Module::Install;

name           'JavaScript-Librarian';
all_from       'lib/JavaScript/Librarian.pm';
requires       'File::Spec'            => '0.82';
requires       'URI'                   => '1.33';
requires       'Clone'                 => '0.13';
requires       'Algorithm::Dependency' => '1.02';
requires       'Params::Coerce'        => '0.06';
build_requires 'Test::More'            => '0.47';

WriteAll;
