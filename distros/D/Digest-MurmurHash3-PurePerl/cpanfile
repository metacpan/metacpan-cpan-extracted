#!perl
requires 'perl' => '5.008008';

on 'configure' => sub {
    requires 'Module::Build' => '0.38';
};

on 'build' => sub {
    requires 'Test::More'     => '0.98';
};

on 'develop' => sub {
    requires 'Test::Spellunker';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Software::License';
};

