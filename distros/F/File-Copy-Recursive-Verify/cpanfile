requires 'perl', '5.008001';

requires 'File::Copy::Verify';
requires 'Try::Tiny::Retry';
requires 'Path::Tiny';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception';
};

on 'develop' => sub {
    requires 'Minilla';
    requires 'Module::Build::Tiny';
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast';
    requires 'Test::PAUSE::Permissions';
    requires 'Test::Pod';
    requires 'Test::Spellunker';
    requires 'Version::Next';
};
