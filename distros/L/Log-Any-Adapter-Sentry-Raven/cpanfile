requires 'Devel::StackTrace';
requires 'Devel::StackTrace::Extract';
requires 'Log::Any::Adapter::Base', '1.708';
requires 'Log::Any::Adapter::Util';
requires 'Sentry::Raven', '!= 1.13';

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};

on test => sub {
    requires 'Capture::Tiny';
    requires 'Log::Any';
    requires 'Log::Any::Adapter';
    requires 'Test::Fatal';
    requires 'Test::MockObject';
};
