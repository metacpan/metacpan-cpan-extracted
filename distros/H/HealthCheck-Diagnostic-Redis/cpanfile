requires 'strict';
requires 'warnings';
requires 'parent';

requires 'Carp';

requires 'HealthCheck::Diagnostic';
requires 'Redis::Fast';

on test => sub {
    requires 'Data::Dumper';
    requires 'Test::MockModule';
    requires 'Test::More';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
