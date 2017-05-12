use strict;
use Test::More tests => 4;

my $class = 'Language::MinCaml::Util';

use_ok($class);

### test create_temp_ident_name
{
    is(create_temp_ident_name({kind => 'hoge'}), 'hoge0');
    is(create_temp_ident_name({kind => 'fuga'}), 'fuga1');
    is(create_temp_ident_name({kind => 'hige'}), 'hige2');
}


