#!perl
requires 'perl' => '5.008008';
requires 'XSLoader';
requires 'Exporter';

on 'configure' => sub {
    requires 'Module::Build::XSUtil';
};

on 'build' => sub {
};

on 'test' => sub {
    requires 'Test::More'     => '0.98';
};

on 'develop' => sub {
    requires 'Test::Spelling';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Software::License';
};

