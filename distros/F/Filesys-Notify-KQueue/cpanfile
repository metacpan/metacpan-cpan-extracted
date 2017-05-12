requires 'IO::KQueue';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'File::Path';
    requires 'Test::More';
    requires 'Test::SharedFork';
    requires 'parent';
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
