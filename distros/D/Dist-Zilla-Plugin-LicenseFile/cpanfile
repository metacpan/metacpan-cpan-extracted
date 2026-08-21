requires 'Dist::Zilla', '6.037';
requires 'Dist::Zilla::Role::FileMunger';
requires 'Dist::Zilla::App';
requires 'Moose';
requires 'Path::Tiny';

on test => sub {
    requires 'Test::More';
    requires 'Test::DZil';
    requires 'Dist::Zilla::Tester';
    requires 'Dist::Zilla::App::Tester';
    requires 'Path::Tiny';
    requires 'File::Temp';
    requires 'File::Find::Rule';
};

on develop => sub {
    requires 'Dist::Zilla';
    requires 'Test::Pod';
};
