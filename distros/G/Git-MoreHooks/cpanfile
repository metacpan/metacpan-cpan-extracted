# At least this Perl version (can be higher):
requires 'perl', '5.016';

on runtime => sub {
    requires 'Git::Hooks', '>= 3.000000';
    requires 'Log::Any';
    requires 'Const::Fast';
    requires 'Path::Tiny';
    requires 'Params::Validate';
};
on test => sub {
    requires 'Test2';
    requires 'Test::CPAN::Meta';
    requires 'Test::Pod::Coverage';
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::Git';
    requires 'Test::Requires::Git';
};

feature 'trigger_jenkins', 'Hook TriggerJenkins' => sub {
    requires 'Template';
    requires 'Jenkins::API';
};
feature 'mailmap', 'Hook CheckCommitAuthorFromMailmap' => sub {
    requires 'Git::Mailmap';
};
feature 'check_perl', 'Hook CheckPerl' => sub {
    requires 'Perl::Critic';
};
