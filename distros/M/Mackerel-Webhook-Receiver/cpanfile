requires 'Class::Accessor::Lite';
requires 'JSON';
requires 'Plack::Request';
requires 'Plack::Runner';
requires 'parent';
requires 'perl', '5.008001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'HTTP::Request::Common';
    requires 'Plack::Test';
    requires 'Test::More', '0.98';
};
