requires 'perl', '5.012';

on 'build' => sub {
	requires 'ExtUtils::CBuilder';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'develop' => sub {
    requires 'Software::License::Artistic_2_0';
    requires 'Data::Dump';
    requires 'Perl::Tidy';
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast';
    requires 'Test::PAUSE::Permissions';
    requires 'Test::Pod', '1.41';
    requires 'Test::Spellunker';
};

requires 'Math::Int64', '0.53'; # 32bit perl without int64 :\

