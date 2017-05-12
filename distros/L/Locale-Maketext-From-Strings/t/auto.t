use strict;
use warnings;
use Locale::Maketext::From::Strings;
use Test::More;

plan skip_all => 'Cannot read t/i18n/en.strings' unless -r 't/i18n/en.strings';

chdir 't';

eval <<"CODE" or die $@;
package MyApp;
Locale::Maketext::From::Strings->load;
our \$NS = Locale::Maketext::From::Strings->new->namespace;
1;
CODE

no warnings 'once';

is $MyApp::NS, 'MyApp::I18N', 'namespace()';

is $INC{'MyApp/I18N.pm'}, 'GENERATED', 'MyApp/I18N.pm generated';
is $INC{'MyApp/I18N/en.pm'}, 'GENERATED', 'MyApp/I18N/en.pm generated';

isa_ok 'MyApp::I18N', 'Locale::Maketext';
isa_ok 'MyApp::I18N::en', 'MyApp::I18N';

done_testing;
