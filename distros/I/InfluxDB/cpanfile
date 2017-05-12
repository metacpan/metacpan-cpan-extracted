# -*- mode: cperl -*-

requires 'perl', '5.010';

requires 'Class::Accessor::Lite';
requires 'Data::Validator';
requires 'Furl';
requires 'JSON', '2';
requires 'Mouse::Util::TypeConstraints';
requires 'URI::Escape';

on configure => sub {
    requires 'Module::Build::Tiny', '0.030';
    requires 'perl', '5.010_000';
    requires 'Module::Build::Tiny', '0.039';
};

on test => sub {
    requires 'Pod::Wordlist';
    requires 'Test::Fixme';
    requires 'Test::Kwalitee';
    requires 'Test::More';
    requires 'Test::Spelling', '0.12';
};
