# Add your requirements here
requires 'perl', 'v5.10.0'; # for kwalitee
requires 'strict';
requires 'warnings';
requires 'parent';

requires 'HealthCheck::Diagnostic';
requires 'Net::SSH::Perl';

on test => sub {
    requires 'Test2::V0';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
