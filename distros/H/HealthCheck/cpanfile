requires 'strict';
requires 'warnings';
requires 'parent';
requires 'Carp';

requires 'Hash::Util::FieldHash';
requires 'List::Util', '>= 1.43';
requires 'Time::HiRes';

on test => sub {
    requires 'Test2::V0';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG', 'v0.0.19';
    requires 'Test::Strict';
};

1;
