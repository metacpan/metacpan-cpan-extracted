requires 'Dist::Zilla', '6.037';
requires 'Dist::Zilla::Role::FileGatherer';
requires 'Dist::Zilla::File::InMemory';
requires 'Moose';
requires 'Path::Tiny';

on test => sub {
    requires 'Test::More';
    requires 'Dist::Zilla::Tester';
    requires 'Path::Tiny';
};

on develop => sub {
    requires 'Dist::Zilla';
};
