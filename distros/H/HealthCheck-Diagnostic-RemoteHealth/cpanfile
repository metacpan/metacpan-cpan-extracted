requires 'perl', 'v5.10.0'; # for kwalitee

requires 'parent';
requires 'strict';
requires 'warnings';

requires 'HealthCheck::Diagnostic::WebRequest', 'v1.4.4';
requires 'JSON';

on test => sub {
    requires 'Test2::V0';
    requires 'LWP::Protocol::http';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
