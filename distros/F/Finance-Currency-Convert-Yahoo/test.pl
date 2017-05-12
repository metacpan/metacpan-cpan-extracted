

use Test;
BEGIN { plan tests => 1 };
use Finance::Currency::Convert::Yahoo;
ok(1); # If we made it this far, we're ok.

warn "# Don't want to go online to test\n# so try something like\n";
warn '# $Finance::Currency::Convert::Yahoo::CHAT=1;'."\n";
warn '# print Finance::Currency::Convert::Yahoo::convert(1,\'EUR\',\'GBP\');'."\n";


# $Finance::Currency::Convert::Yahoo::CHAT=1;
# print Finance::Currency::Convert::Yahoo::convert(10,'GBP','HUF');

exit;

