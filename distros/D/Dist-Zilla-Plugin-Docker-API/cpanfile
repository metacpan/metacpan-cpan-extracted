requires 'perl', '5.014';
requires 'API::Docker', '0.006';
requires 'Archive::Tar';
requires 'Carp';
requires 'Dist::Zilla::Role::AfterBuild';
requires 'Dist::Zilla::Role::BeforeBuild';
requires 'Dist::Zilla::Role::Plugin';
requires 'Dist::Zilla::Role::Releaser';
requires 'JSON::MaybeXS';
requires 'Log::Any';
requires 'MIME::Base64';
requires 'Moo';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Path::Tiny';
requires 'Types::Standard';

on test => sub {
    requires 'Capture::Tiny';
    requires 'File::Temp';
    requires 'Path::Tiny';
    requires 'Test::DZil';
    requires 'Test::More';
    requires 'Test::Warnings';
};

on develop => sub {
    requires 'Dist::Zilla';
    requires 'Perl::Critic';
    requires 'Test::Pod';
};
