requires 'perl', '5.010001';

requires 'Scalar::Util';
requires 'Socket';
requires 'Sys::Syslog', '0.29';
requires 'Time::HiRes';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'File::Temp';
    requires 'Test::Exception';
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
