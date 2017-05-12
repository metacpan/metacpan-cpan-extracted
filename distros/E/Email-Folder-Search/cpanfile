requires 'Email::Folder', "0.860";
requires 'Encode';
requires 'Scalar::Util';
requires 'Email::MIME';
requires 'mro';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.48';
};

on build => sub {
    requires 'perl', '5.010000';
};

on test => sub {
    requires 'Test::More';
    requires 'Test::Exception';
    requires 'Try::Tiny';
    requires 'FindBin';
    requires 'Path::Tiny';
};

