requires 'Log::Any::Adapter::Base', '1.708';
requires 'Log::Any::Adapter::Util';
requires 'Sentry::Raven';

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
    requires 'Devel::StackTrace';
};

on test => sub {
    requires 'Capture::Tiny';
    requires 'Log::Any';
    requires 'Log::Any::Adapter';
    requires 'Test::Fatal';
    requires 'Test::MockObject';
    requires 'Test::Needs';
    requires 'Test::Without::Module';
};
