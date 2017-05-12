requires 'perl', '5.010001';

requires 'Crypt::MatrixSSL3', 'v3.7.4';
requires 'IO::Stream';
requires 'IO::Stream::const';
requires 'Scalar::Util';
requires 'parent';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'EV';
    requires 'File::Temp';
    requires 'Socket';
    requires 'Test::Exception';
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
