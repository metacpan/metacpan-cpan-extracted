requires 'Exporter';
requires 'XSLoader';
requires 'parent';
requires 'perl', '5.008008';

on configure => sub {
    requires 'Devel::PPPort', '3.20';
    requires 'Module::Build::Pluggable::PPPort', '0.01';
};

on build => sub {
    requires 'Devel::PPPort', '3.20';
    requires 'ExtUtils::CBuilder';
    requires 'Module::Build::Pluggable::PPPort', '0.04';
    requires 'Test::More', '0.98';
    requires 'Test::Requires';
};
