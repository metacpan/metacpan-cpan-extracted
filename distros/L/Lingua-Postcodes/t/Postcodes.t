use Test::More tests => 11;
use utf8;

binmode Test::More->builder->$_, ":utf8" for qw/output failure_output todo_output/;

BEGIN {
        use_ok( 'Lingua::Postcodes' );
}

is Lingua::Postcodes::name('IE'), 'Eircode', 'Works okay without importing';

use Lingua::Postcodes 'name';

is name('XPTO'), undef, 'Returns UNDEF if country code does not exist';

is name('GB'), 'Postcode', '"GB" returns "Postcode"';
is name('IE'), 'Eircode', '"IE" returns "Eircode"';

is name('GB', 'EN'), 'Postcode', '"GB" returns "Postcode" when using "EN" language parameter';
is name('GB', 'FR'), '?', '"GB" returns "?" when using "FR" language parameter - As I do not know the French';

is name('FR', 'EN'), 'Postal code', '"FR" returns "Postal code" when using "EN" language parameter';
is name('FR', 'FR'), 'Code postal', '"FR" returns "Code postal" when using "FR" language parameter';

# Romania with UTF8 character
is name('RO', 'EN'), 'Postal code', '"RO" returns "Postal code" when using "EN" language parameter';
is name('RO', 'RO'), 'Cod poștal', '"RO" returns "Cod poștal" when using "RO" language parameter';
