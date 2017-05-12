# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 9 };
use Lingua::ES::Silabas;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

# numero de silabas (en realidad esto no depende de mi, pero no esta de mas)
ok( silabas('hormigueo') == 4 );

# una consonante entre dos vocales
ok( join('-', silabas('suelo')) eq 'sue-lo' );

# dos consonantes entre dos vocales
ok( join('-', silabas('once')) eq 'on-ce' );
ok( join('-', silabas('cobre')) eq 'co-bre' );

# tres consonantes entre dos vocales
ok( join('-', silabas('transportar')) eq 'trans-por-tar' );
ok( join('-', silabas('contra')) eq 'con-tra' );

# cuatro consonantes entre dos vocales
ok( join('-', silabas('instructor')) eq 'ins-truc-tor' );

# hiato
ok( join('-', silabas('petroleo')) eq 'pe-tro-le-o' );
