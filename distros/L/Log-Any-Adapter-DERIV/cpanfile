requires 'curry', '>= 1.001000';
requires 'JSON::MaybeUTF8', '>= 1.002';
requires 'Log::Any', '>= 1.709';
requires 'Log::Any::Adapter::Coderef', '>= 0.002';
requires 'Path::Tiny', '>= 0.118';
requires 'PerlIO', 0;
requires 'Term::ANSIColor', '>= 5.01';
requires 'Time::Moment', '>= 0.44';
requires 'File::HomeDir', 0;

on 'test' => sub {
    requires 'Test::More', '>= 0.98';
    requires 'Test::Deep', '>= 1.130';
    requires 'Test::Fatal', '>= 0.014';
    requires 'Log::Any::Test';
    requires 'Test::CheckDeps';
};

on 'develop' => sub {
    requires 'Devel::Cover::Report::Coveralls', '>= 0.11';
    requires 'Devel::Cover';
};
