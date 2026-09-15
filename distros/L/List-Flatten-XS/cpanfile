requires 'perl', '5.008001';

on 'configure' => sub {
    requires 'Module::Build::XSUtil', '0.19';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception';
    requires 'Test::LeakTrace';
    requires 'Test::Valgrind';
};
