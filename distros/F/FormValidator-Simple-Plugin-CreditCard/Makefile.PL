use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'FormValidator::Simple::Plugin::CreditCard',
    VERSION_FROM      => 'lib/FormValidator/Simple/Plugin/CreditCard.pm', # finds $VERSION
    PREREQ_PM         => {
        FormValidator::Simple => 0.01,
        Business::CreditCard => 0.28,
    }, # e.g., Module::Name => 1.1
);
