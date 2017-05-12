requires 'Class::Accessor::Lite';
requires 'JSON';
requires 'Plack::Middleware::HubSignature', '0.02';
requires 'Plack::Request';
requires 'Plack::Runner';
requires 'parent';
requires 'perl', '5.008001';

on configure => sub {
    requires 'Module::Build';
};

on test => sub {
    requires 'HTTP::Request::Common';
    requires 'Plack::Test';
    requires 'Test::More', '0.98';
};
