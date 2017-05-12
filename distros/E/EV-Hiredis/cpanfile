requires 'perl', '5.008001';
requires 'EV', '4.11';
requires 'XSLoader', '0.02';

on configure => sub {
    requires 'EV::MakeMaker';
    requires 'Module::Build::XSUtil' => '>=0.02';
    requires 'File::Which';
};

on build => sub {
    requires 'Devel::Refcount';
    requires 'Test::Deep';
    requires 'Test::More', '0.98';
    requires 'Test::RedisServer', '0.12';
    requires 'Test::TCP', '1.18';
};
