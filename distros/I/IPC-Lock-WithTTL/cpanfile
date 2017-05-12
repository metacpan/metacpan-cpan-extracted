# -*- mode: cperl -*-

requires 'perl', '5.008005';

requires 'Smart::Args';
requires 'Class::Accessor::Lite';

on configure => sub {
    requires 'Module::Build::Tiny', '0.039';
};

on develop => sub {
    requires 'Test::More', '0.96';
    requires 'App::scan_prereqs_cpanfile', '0.09';
    requires 'Pod::Wordlist';
    requires 'Test::Kwalitee', '1.21';
    requires 'Test::Pod', '1.41';
    requires 'Test::Vars';
    requires 'Test::Spelling', '0.12';
    requires 'Test::Fixme';
};

on test => sub {
    requires 'Test::More';
    requires 'File::Temp';
};
