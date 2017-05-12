use POSIX qw(locale_h);
use Test::More tests => 20;

BEGIN { use_ok( Math::Currency ); }

my $locale = setlocale( LC_ALL );
ok ( $locale, 'Got current locale' );

for my $currency_code (qw(USD EUR GBP CAD AUD JPY ZAR)) {
    Math::Currency->format($currency_code);

    is ( setlocale( LC_ALL ), $locale,
        "Setting currency format did not change the locale ".
        "($currency_code)"); 

    my $currency_obj = Math::Currency->new('1.23', $currency_code);

    is ( setlocale( LC_ALL ), $locale,
        "Setting currency for single object did not change the ".
        "locale ($currency_code)"); 
}

for my $invalid_currency_code (qw(ABC DEF GHI JKL)) {
    Math::Currency->format($invalid_currency_code);

    is ( setlocale( LC_ALL ), $locale,
        "Setting invalid currency format did not change the locale ".
        "($invalid_currency_code)"); 
}
