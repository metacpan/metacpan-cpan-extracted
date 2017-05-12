use inc::Module::Install;

# Define metadata
name           'Mac-Safari-JavaScript';
all_from       'lib/Mac/Safari/JavaScript.pm';

requires       'Test::More'       => 0;
requires       'Mac::AppleScript' => 0.04;
requires       'JSON::XS'         => 2.3;

license 'perl';
githubmeta;

WriteAll;
