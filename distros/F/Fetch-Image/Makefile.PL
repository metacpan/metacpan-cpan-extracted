use inc::Module::Install;

all_from('lib/Fetch/Image.pm');

requires 'LWP::UserAgent::Paranoid';
requires 'Data::Validate::Image';
requires 'Data::Validate::URI';
requires 'File::Temp';
requires 'Exception::Simple';
requires 'URI';

test_requires 'Test::More';
test_requires 'Test::Exception';

perl_version '5.008';

resources(
    'bugtracker'  => 'https://github.com/markwellis/fetch-image/issues',
    'repository'  => 'https://github.com/markwellis/fetch-image.git',
);

auto_install;
WriteAll;
