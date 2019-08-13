requires 'HTTP::Request';
requires 'JSON::XS';
requires 'LWP::UserAgent';
requires 'Mouse';
requires 'URI';
requires 'URI::QueryParam';
requires 'WWW::Google::Cloud::Auth::ServiceAccount';
requires 'perl', '5.008001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'MIME::Base64';
    requires 'Test::Deep';
    requires 'Test::Exception';
    requires 'Test::More', '0.98';
    requires 'Time::HiRes';
};
