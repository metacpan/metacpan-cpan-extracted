requires 'perl', '5.010001';

requires 'Crypt::RC4';
requires 'IO::Stream';
requires 'IO::Stream::const';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'EV';
    requires 'File::Temp';
    requires 'Scalar::Util';
    requires 'Socket';
    requires 'Test::Exception';
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
