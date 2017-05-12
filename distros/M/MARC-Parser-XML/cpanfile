requires 'perl', 'v5.10.1';

requires 'Carp';
requires 'XML::LibXML::Reader';

on 'develop', sub {
    requires 'Code::TidyAll', 0;
    requires 'Perl::Tidy', 0;
    requires 'Test::Code::TidyAll', '0.20';
    requires 'Text::Diff', 0; # undeclared Test::Code::TidyAll plugin dependency
    requires 'Test::Perl::Critic';
};

on test => sub {
    requires 'Test::More';
};
