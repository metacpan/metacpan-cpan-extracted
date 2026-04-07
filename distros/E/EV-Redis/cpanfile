requires 'perl', '5.012000';
requires 'EV', '4.11';
requires 'XSLoader', '0.02';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.64';
    requires 'EV::MakeMaker';
    requires 'File::Which';
};

on test => sub {
    requires 'Devel::Refcount';
    requires 'Test::Deep';
    requires 'Test::More', '0.98';
    requires 'Test::RedisServer', '0.12';
    requires 'Test::TCP', '1.18';
};

on develop => sub {
    requires 'Test::Pod', '1.41';
    requires 'Test::Spellunker', 'v0.2.7';
    requires 'Test::MinimumVersion::Fast', '0.04';
    requires 'Test::CPAN::Meta';
};
