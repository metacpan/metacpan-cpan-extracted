requires 'perl', '5.022';
recommends 'Math::Int64', '0.53';
recommends 'perl',        '5.022';
on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
    requires 'perl',                'v5.40.0';
};
on build => sub {
    requires 'ExtUtils::CBuilder';
    requires 'Module::Build';
};
on test => sub {
    requires 'Test2::V0';
};
on develop => sub {
    requires 'Data::Dump';
    requires 'Perl::Tidy';
    requires 'Software::License::Artistic_2_0';
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast';
    requires 'Test::PAUSE::Permissions';
    requires 'Test::Pod', '1.41';
    requires 'Test::Spellunker';
};
