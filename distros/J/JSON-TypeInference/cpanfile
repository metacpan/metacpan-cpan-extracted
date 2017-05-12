requires 'perl', '5.008001';

requires 'List::Util', '>= 1.33';
requires 'List::UtilsBy';
requires 'Scalar::Util';
requires 'Types::Serialiser';

on 'test' => sub {
    requires 'Devel::Cover';
    requires 'Devel::Cover::Report::Coveralls';
    requires 'Test::Deep';
    requires 'Test::More', '0.98';
};

on 'build' => sub {
    requires 'Test::Deep';
};

