requires 'perl', '5.010001';

requires 'IO::Stream';
requires 'IO::Stream::const';
requires 'MIME::Base64';
requires 'Scalar::Util';

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
