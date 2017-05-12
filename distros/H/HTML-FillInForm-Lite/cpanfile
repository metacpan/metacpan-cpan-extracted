#!perl
requires 'perl', '5.008001';

on develop => sub {
    requires 'Minilla';
};

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.59';
};

on test => sub {
    requires 'CGI';
    requires 'Test::More', '0.62';
    requires 'Test::Requires';
};
