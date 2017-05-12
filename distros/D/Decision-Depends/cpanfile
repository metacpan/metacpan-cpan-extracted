#!perl


requires 'YAML';
requires 'Tie::IxHash';
requires 'Data::Compare';
requires 'Clone';

on 'test' => sub {
    requires 'Test::More';
    requires 'Test::Deep';
    requires 'Test::TempDir::Tiny','0.005';
};

on develop => sub {

    requires 'Module::Install';
    requires 'Module::Install::AuthorRequires';
    requires 'Module::Install::AuthorTests';
    requires 'Module::Install::AutoLicense';
    requires 'Module::Install::CPANfile';

    requires 'Test::NoBreakpoints';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Perl::Critic';
    requires 'Test::CPAN::Changes';
    requires 'Test::CPAN::Meta';
    requires 'Test::CPAN::Meta::JSON';

};
