requires 'parent';
requires 'strict';
requires 'warnings';
requires 'Carp';

requires 'HealthCheck::Diagnostic';

requires 'Scalar::Util';

on test => sub {
    requires 'DBD::SQLite';
    requires 'DBI';
    requires 'Test::More';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
    requires 'Test::Strict';
};
