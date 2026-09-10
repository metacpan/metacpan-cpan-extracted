use Modern::Perl;
use Test::More;

BEGIN {
    # Namespace modules
    use_ok('Koha::QA');
    use_ok('Koha::QA::Base');
    use_ok('Koha::QA::Security');
    use_ok('Koha::QA::Tidy');

    # Security modules
    use_ok('Koha::QA::Security::TemplateFilters');
    use_ok('Koha::QA::Security::CSRF');
    use_ok('Koha::QA::Security::Nonce');

    # Tidy modules
    use_ok('Koha::QA::Tidy::Perl');
    use_ok('Koha::QA::Tidy::JS');
    use_ok('Koha::QA::Tidy::TT');

    use_ok('Koha::QA::PerlSyntax');
    use_ok('Koha::QA::PerlCritic');
    use_ok('Koha::QA::PodChecker');
    use_ok('Koha::QA::Spelling');
    use_ok('Koha::QA::FilePermissions');
    use_ok('Koha::QA::TestNoWarnings');
}

done_testing();
