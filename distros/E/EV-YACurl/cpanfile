requires 'perl', '5.010000';
requires 'EV', '4.11';
requires 'Alien::curl';

on configure => sub {
    requires 'Alien::curl';
    requires 'EV::MakeMaker';
    requires 'ExtUtils::MakeMaker', '6.64';
};

on test => sub {
    requires 'Test::More', '0.98';
    recommends 'Test::LeakTrace';
};
