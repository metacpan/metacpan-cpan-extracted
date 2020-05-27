requires 'Exporter';
requires 'Moo';
requires 'MooX::HandlesVia';
requires 'Scalar::Util';
requires 'Types::Standard';
requires 'namespace::clean';

on test => sub {
    requires 'Test2::Bundle::More';
    requires 'Test2::Tools::Exception';
    requires 'strict';
    requires 'warnings';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
    requires 'Test2::Require::AuthorTesting';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Strict';
    requires 'Test::Version';
};
