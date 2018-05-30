requires 'perl', '5.008005';

requires 'Cpanel::JSON::XS', '0';
requires 'File::Share', '0';
requires 'File::Slurper', '0';
requires 'Getopt::Long', '0';
requires 'MARC::Parser::RAW', '0';
requires 'MARC::Parser::XML', '0';
requires 'Scalar::Util', '0';

on 'develop', sub {
    requires 'Code::TidyAll', '0';
    requires 'Perl::Tidy', '0';
    requires 'Test::Code::TidyAll', '0.20';
    requires 'Test::Perl::Critic', '0';
    requires 'Text::Diff', '0'; # undeclared Test::Code::TidyAll plugin dependency
};

on test => sub {
    requires 'Test2::V0', '0';
    requires 'Test::More', '0.96';
    requires 'Test::Script', '0';
};