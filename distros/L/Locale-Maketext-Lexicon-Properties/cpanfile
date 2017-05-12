requires 'perl', '5.008005';
requires 'Encode';
requires 'Locale::Maketext::Lexicon';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'parent';
    requires 'Test::More', '0.98';
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
