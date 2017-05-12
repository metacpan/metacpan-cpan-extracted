requires 'perl', '5.008001';
requires 'GitDDL', '0.03';
requires 'SQL::Translator';
requires 'Mouse';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'DBI';
    requires 'Test::Git';
    requires 'Test::Requires::Git', '1.005';
    requires 'Test::More', '0.98';
    requires 'Test::Requires';

    recommends 'Test::mysqld';
};
