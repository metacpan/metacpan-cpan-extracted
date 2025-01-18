#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Bgn';
use ok 'Locale::CLDR::Locales::Bgn::Arab::Ae';
use ok 'Locale::CLDR::Locales::Bgn::Arab::Af';
use ok 'Locale::CLDR::Locales::Bgn::Arab::Ir';
use ok 'Locale::CLDR::Locales::Bgn::Arab::Om';
use ok 'Locale::CLDR::Locales::Bgn::Arab::Pk';
use ok 'Locale::CLDR::Locales::Bgn::Arab';

done_testing();
