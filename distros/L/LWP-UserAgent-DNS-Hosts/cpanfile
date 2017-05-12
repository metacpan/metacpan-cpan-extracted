requires 'LWP::Protocol';
requires 'LWP::Protocol::http';
requires 'Scope::Guard';
requires 'parent';
requires 'perl', '5.008001';

on test => sub {
    requires 'File::Temp';
    requires 'LWP::UserAgent';
    requires 'Test::Fake::HTTPD', '0.08';
    requires 'Test::More', '0.98';
    requires 'Test::UseAllModules';
};

feature 'https', 'SSL support' => sub {
    recommends 'LWP::Protocol::https';

    on test => sub {
        requires 'HTTP::Daemon::SSL';
    };
};
