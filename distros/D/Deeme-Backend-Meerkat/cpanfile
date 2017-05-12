requires 'Deeme';
requires 'Deeme::Obj';
requires 'Deeme::Utils';
requires 'Meerkat';
requires 'Meerkat::Role::Document';
requires 'Moose';
requires 'feature';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.006';
};

on test => sub {
    requires 'MongoDB::Connection';
    requires 'Test::More';
};
