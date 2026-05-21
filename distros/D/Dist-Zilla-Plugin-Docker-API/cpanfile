requires 'Dist::Zilla::Role::Plugin';
requires 'Dist::Zilla::Role::AfterBuild';
requires 'Dist::Zilla::Role::Releaser';
requires 'API::Docker', '0.002';
requires 'Moo';
requires 'Types::Standard';
requires 'Path::Tiny';
requires 'Archive::Tar::Wrapper';
requires 'Log::Any';
requires 'JSON::MaybeXS';
requires 'MIME::Base64';

on test => sub {
    requires 'Test::More';
    requires 'Test::DZil';
    requires 'Path::Tiny';
    requires 'File::Temp';
    requires 'Capture::Tiny';
};

on develop => sub {
    requires 'Dist::Zilla';
    requires 'Perl::Critic';
    requires 'Test::Pod';
};