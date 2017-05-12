use inc::Module::Install;

all_from('lib/HTML/Video/Embed.pm');

requires 'Moo';
requires 'Moo::Role';
requires 'URI';
requires 'URI::QueryParam';
requires 'URI::Escape::XS';
requires 'Data::Validate::URI';
requires 'Module::Find';

test_requires 'Test::More';

perl_version '5.008';

resources(
    'bugtracker'  => 'https://github.com/markwellis/html-video-embed/issues',
    'repository'  => 'https://github.com/markwellis/html-video-embed.git',
);

auto_install;
WriteAll;
