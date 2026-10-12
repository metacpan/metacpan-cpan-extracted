# cpanfile
requires 'perl' => '5.010';

# Runtime dependencies
requires 'MP3::Tag';

# Configure dependencies
on configure => sub {
    requires 'ExtUtils::MakeMaker' => '7.22';
};

# Test dependencies
on test => sub {
    requires 'Test::More' => '0.90';
};

on develop => sub {
    requires 'Devel::Cover'  => '1.52';
    requires 'Test::Kwalitee' => '1.28';
    requires 'Perl::Critic'  => '0';
    requires 'Perl::Tidy'    => '20170521';
    requires 'Perl::Version' => '1.013';
    requires 'Pod::Text' => '6.1.1';
};
