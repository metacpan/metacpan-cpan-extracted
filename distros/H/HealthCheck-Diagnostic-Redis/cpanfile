requires 'strict';
requires 'warnings';
requires 'parent';

requires 'Carp';

requires 'HealthCheck::Diagnostic';
requires 'Redis::Fast';
requires 'String::Random';

on test => sub {
    requires 'Data::Dumper';
    requires 'Test::MockModule';
    requires 'Test::More';
    requires 'Test::Differences';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
