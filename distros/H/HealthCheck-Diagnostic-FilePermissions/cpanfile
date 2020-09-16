requires 'parent';
requires 'strict';
requires 'warnings';

requires 'Carp';

requires 'HealthCheck::Diagnostic', 'v1.6';

on test => sub {
    requires 'File::Temp';
    requires 'Test::Differences';
    requires 'Test::More';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
