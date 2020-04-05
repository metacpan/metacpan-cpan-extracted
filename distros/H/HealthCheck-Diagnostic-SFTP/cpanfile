requires 'parent';
requires 'strict';
requires 'warnings';

requires 'Carp';

requires 'HealthCheck::Diagnostic';
requires 'Net::SFTP';
requires 'Net::SSH::Perl::Buffer';

on test => sub {
    requires 'Test::Differences';
    requires 'Test::MockModule';
    requires 'Test::More';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
