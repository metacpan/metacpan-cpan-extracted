requires 'Carp';
requires 'Class::Std::Utils';
requires 'Encode';
requires 'HTML::Entities';
requires 'Moo';
requires 'Scalar::Util';
requires 'String::Random';
requires 'URI::Escape';
requires 'namespace::clean';
requires 'perl', '5.014';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    requires 'Test::Exception';
    requires 'Test::FailWarnings';
    requires 'Test::More', '0.96';
    requires 'Test::Perl::Critic';
};
