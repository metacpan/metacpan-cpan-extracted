
use strict;
use warnings;

use Test::More tests => 3;

use Log::Any::Adapter::Util qw( numeric_level WARNING );

### Test that numeric level works with aliases, case-insensitive
is numeric_level( 'warn' ), WARNING(), 'warn alias is correct';
is numeric_level( 'Warn' ), WARNING(), 'Warn alias is correct';
is numeric_level( 'WARN' ), WARNING(), 'WARN alias is correct';

