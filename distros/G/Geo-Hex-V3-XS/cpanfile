requires 'Exporter', '5.57';

on configure => sub {
    requires 'Cwd::Guard';
    requires 'Module::Build::XSUtil';
    requires 'File::Which';
    requires 'parent';
};

on test => sub {
    requires 'Test::More', '0.98';
};

on develop => sub {
    requires 'Test::LeakTrace';
};
