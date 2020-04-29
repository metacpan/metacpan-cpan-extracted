requires 'parent';
requires 'strict';
requires 'warnings';
requires 'Carp';

requires 'HealthCheck::Diagnostic';

requires 'HTTP::Request';
requires 'LWP::UserAgent';
requires 'Scalar::Util';

on test => sub {
    requires 'Test::MockModule';
    requires 'Test::More';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
