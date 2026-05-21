requires 'perl', '5.012000';
requires 'EV', '4.11';
requires 'XSLoader';

on configure => sub {
    requires 'EV::MakeMaker';
    requires 'ExtUtils::MakeMaker', '6.64';
};

on test => sub {
    requires 'Test::More', '0.98';
};

# Author-only tests in xt/ each guard their dependency with eval/skip_all,
# so missing modules just turn into a skipped test rather than a build
# failure. Listed here so `cpanm --with-develop` and authors picking up
# the dist can install them in one shot.
on develop => sub {
    recommends 'Test::Pod',             '1.22';
    recommends 'Test::Pod::Coverage',   '1.08';
    recommends 'Test::Kwalitee::Extra', '0';
    recommends 'Test::CPAN::Changes',   '0';
    recommends 'Test::LeakTrace',       '0';
};
