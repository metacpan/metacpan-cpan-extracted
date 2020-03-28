requires 'parent';
requires 'strict';
requires 'warnings';

requires 'Carp';

requires 'HealthCheck::Diagnostic';

on test => sub {
    requires 'Test::More';
    requires 'Test::Strict';
    requires 'DBI';
    requires 'DBD::SQLite';
};


on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};

1;
on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG::Internal';
};
