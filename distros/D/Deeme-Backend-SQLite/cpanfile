requires 'DBD::SQLite';
requires 'DBI';
requires 'Deeme';
requires 'Deeme::Backend::DBI';
requires 'Deeme::Obj';
requires 'Deeme::Utils';
requires 'feature';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.008005';
};

on test => sub {
    requires 'Carp::Always';
    requires 'Test::More';
};
