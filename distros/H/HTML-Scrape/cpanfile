# Validate with cpanfile-dump
# https://metacpan.org/release/Module-CPANfile

requires 'HTML::Parser' => '0';

on 'configure' => sub {
    requires 'ExtUtils::MakeMaker' => '6.64';
};

on 'test' => sub {
    requires 'Test::More' => '0.98';
    requires 'Test::Warnings' => '0';
};
