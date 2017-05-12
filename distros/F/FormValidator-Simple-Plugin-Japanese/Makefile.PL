use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'FormValidator::Simple::Plugin::Japanese',
    VERSION_FROM      => 'lib/FormValidator/Simple/Plugin/Japanese.pm', # finds $VERSION
    PREREQ_PM         => {
        FormValidator::Simple => 0.03,
        Jcode => 0,
        Unicode::RecursiveDowngrade => '0.02',
        Mail::Address::MobileJp => 0.07,
        FormValidator::Simple::Plugin::Number::Phone::JP => '0.01',
    }, # e.g., Module::Name => 1.1
);
