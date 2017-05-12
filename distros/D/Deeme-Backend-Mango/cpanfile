requires 'Deeme';
requires 'Deeme::Obj';
requires 'Deeme::Utils';
requires 'Mango';
requires 'feature';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.006';
};

on test => sub {
    requires 'Carp::Always';
    requires 'MongoDB::Connection';
    requires 'Test::More';
};
