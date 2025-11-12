# Add your requirements here
requires 'perl', 'v5.10.0'; # for kwalitee

requires 'HealthCheck', 'v1.8.1';
requires 'Parallel::ForkManager';
requires 'Scalar::Util';

on test => sub {
    requires 'Test2::V0';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
