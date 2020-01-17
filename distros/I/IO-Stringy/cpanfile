on 'runtime' => sub {
    requires 'perl' => '5.008';
    requires 'strict';
    requires 'warnings';
    requires 'overload';
    requires 'parent';
    requires 'Carp';
    requires 'Exporter' => '5.57';
    requires 'File::Spec';
    requires 'FileHandle';
    requires 'IO::File';
    requires 'IO::Handle';
    requires 'Symbol';
};

on 'build' => sub {
    requires 'ExtUtils::MakeMaker';
};

on 'test' => sub {
    requires 'strict';
    requires 'warnings';
    requires 'ExtUtils::MakeMaker';
    requires 'File::Basename';
    requires 'File::Spec';
    requires 'File::Temp';
    requires 'FileHandle';
    requires 'IO::File';
    requires 'IO::Handle';
    requires 'Symbol';
    requires 'Test::More' => '0.88'; # already uses done_testing
    requires 'Test::Tester';
};

on 'develop' => sub {
    requires 'Dist::Zilla';
    requires 'Test::CheckManifest' => '1.29';
    requires 'Test::CPAN::Changes' => '0.4';
    requires 'Test::Kwalitee'      => '1.22';
    requires 'Test::Pod';
    requires 'Test::Pod::Spelling::CommonMistakes' => '1.000';
    requires 'Test::TrailingSpace';
};