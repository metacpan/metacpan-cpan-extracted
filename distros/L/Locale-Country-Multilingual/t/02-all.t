#!perl -T

use Test::More tests => 4;

use Locale::Country::Multilingual;
my $lcm = Locale::Country::Multilingual->new();

my @codes   = $lcm->all_country_codes();
ok(grep(/^CN$/, @codes), "all_country_codes() works");

my $CODE = 'LOCALE_CODE_ALPHA_3';
@codes   = $lcm->all_country_codes($CODE);
ok(grep(/^CHN$/, @codes), "all_country_codes('LOCALE_CODE_ALPHA_3') works");

my @names   = $lcm->all_country_names();
ok(grep(/^China$/i, @names), "all_country_names() works");

my $lang = 'zh';
@names   = $lcm->all_country_names($lang);
ok(grep(/^中国$/, @names), "all_country_names('zh') works");
