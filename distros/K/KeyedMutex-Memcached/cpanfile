requires 'Scope::Guard';
requires 'Time::HiRes';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'Cache::Memcached::Fast';
    requires 'File::Which';
    requires 'Proc::Guard';
    requires 'Test::More';
    requires 'Test::Skip::UnlessExistsExecutable';
    requires 'Test::TCP';
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
