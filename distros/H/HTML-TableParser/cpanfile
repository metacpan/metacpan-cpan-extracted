#!perl

on runtime => sub {

   requires 'HTML::Entities';
   requires 'HTML::Parser' => 3.26;

};

on develop => sub {

    requires 'Test::NoBreakpoints';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Perl::Critic';
    requires 'Test::Compile';
    requires 'Test::CPAN::Changes';

    requires 'Module::Install';
    requires 'Module::Install::AuthorTests';
    requires 'Module::Install::CPANfile';
    requires 'Module::Install::AutoLicense';

};

on test => sub {

    requires 'Test::More' => 0.32;

};
