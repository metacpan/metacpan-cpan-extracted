#!perl
requires 'parent';
requires 'Coro';
requires 'Furl';

on 'configure' => sub {
    requires 'Module::Build::Pluggable';
    requires 'Module::Build::Pluggable::CPANfile';
    requires 'Module::Build::Pluggable::GithubMeta';
};

on 'build' => sub {
};

on 'test' => sub {
    requires 'Test::Requires' => '0.06';
    requires 'Test::More'     => '0.98';
};

on 'develop' => sub {
};
