requires 'perl', '5.012000';
requires 'EV', '4.11';
requires 'Alien::MariaDB';

on configure => sub {
    requires 'Alien::MariaDB';
    requires 'EV::MakeMaker';
    requires 'ExtUtils::MakeMaker', '6.64';
};

on test => sub {
    requires 'Test::More', '0.98';
};
