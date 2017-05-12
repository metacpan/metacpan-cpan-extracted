on 'runtime' => sub {
    requires 'perl' => '5.008001';
    requires 'base';
    requires 'strict';
    requires 'warnings';
    requires 'Carp';
    requires 'Encode';
    requires 'Exporter';
    requires 'File::Basename';
    requires 'IO::Handle';
    requires 'IO::Socket::INET';
    requires 'MIME::Base64';
    requires 'MIME::QuotedPrint';
    requires 'Socket';
    requires 'Symbol';
    requires 'Tie::Handle';
    requires 'Time::Local';
    requires 'Win32API::Registry' if $^O eq 'MSWin32';

    recommends 'Authen::NTLM';
    recommends 'Digest::HMAC_MD5';
    recommends 'IO::Socket::SSL';
    recommends 'Mozilla::CA';
    recommends 'Net::SSLeay';
};

on 'test' => sub {
    requires 'Test::More' => '0.88';
};

on 'develop' => sub {
    requires 'Test::CheckManifest' => '1.29';
    requires 'Test::CPAN::Changes' => '0.4';
    requires 'Test::Kwalitee'      => '1.22';
    requires 'Test::Pod::Spelling::CommonMistakes' => '1.000';
};
