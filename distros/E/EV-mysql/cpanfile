requires 'perl', '5.012000';
requires 'EV', '4.11';
requires 'Alien::MySQL';

on 'configure' => sub {
    requires 'Alien::MySQL';
    requires 'EV', '4.11';
    requires 'EV::MakeMaker';
    requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
};
