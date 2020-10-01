on 'runtime' => sub {
    requires 'strict';
    requires 'warnings';
    requires 'Exporter';
    requires 'XSLoader';
};

on 'configure' => sub {
    requires 'ExtUtils::MakeMaker';
};

on 'test' => sub {
    requires 'strict';
    requires 'warnings';
    requires 'Test';
    requires 'Test::More';
};

on 'develop' => sub {
    requires 'Dist::Zilla';
    requires 'Dist::Zilla::PluginBundle::Starter' => 'v4.0.0';
    requires 'Dist::Zilla::Plugin::MinimumPerl';
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::CheckManifest' => '1.29';
    requires 'Test::CPAN::Changes' => '0.4';
    requires 'Test::CPAN::Meta';
    requires 'Test::Kwalitee'      => '1.22';
    requires 'Test::Pod::Coverage';
    requires 'Test::Pod::Spelling::CommonMistakes' => '1.000';
};
