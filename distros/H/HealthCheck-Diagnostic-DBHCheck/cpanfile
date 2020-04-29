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
    requires 'Test::Strict';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
