#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 7;

use List::Breakdown 'breakdown';

our $VERSION = '0.22';

my @t = 1 .. 3;

# The wrong kind of reference as a spec is fatal
is( eval { breakdown [ a => 'a' ], @t } || undef,
    undef, 'error_wrongref_spec' );

# An undefined value in spec hashref is fatal
is( eval { breakdown { a => undef }, @t } || undef,
    undef, 'error_notref_undef' );

# A non-reference value in spec hashref is fatal
is( eval { breakdown { a => 'a' }, @t } || undef, undef, 'error_notref_def' );

# Any number of items in the numeric range shortcut besides 2 is fatal
is( eval { breakdown { a => [] },  @t } || undef, undef, 'error_badref_array' );
is( eval { breakdown { a => [1] }, @t } || undef, undef, 'error_badref_array' );
is( eval { breakdown { a => [ 1, 2, 3 ] }, @t } || undef,
    undef, 'error_badref_array' );

# A double reference as a value in a spec hashref is fatal
is( eval { breakdown { a => \{} }, @t } || undef, undef,
    'error_badref_double' );
