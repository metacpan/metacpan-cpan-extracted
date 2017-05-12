# -*- perl -*-
#$Id: 01_load.t 1121 2007-01-01 14:43:51Z jimk $
# t/01_load.t - check module loading and test constructor
use strict;
use warnings;

use Test::More tests => 14;
use_ok( 'List::RewriteElements' );


my $lre;

eval { $lre  = List::RewriteElements->new (); };
like($@, qr/^Hash ref passed to constructor must contain 'body_rule' element/,
    "Constructor's arguments lacked a body_rule key");

eval { $lre  = List::RewriteElements->new ( {
    body_rule   => [],
} ); };
like($@, qr/'body_rule' element value must be a code ref/,
    "body_rule key value must be a code ref");

eval { $lre  = List::RewriteElements->new ( {
    body_rule   => sub {},
} ); };
like($@, qr/^Hash ref passed to constructor must have either a 'file' element or a 'list' element/,
    "Must have either a 'file' element or a 'list' element");

eval { $lre  = List::RewriteElements->new ( {
    body_rule   => sub {},
    file        => 'abracadabra',
} ); };
like($@, qr/^'file' element passed to constructor not located/,
    "Constructor correctly failed when value of 'file' element was not found");

eval { $lre  = List::RewriteElements->new ( {
    body_rule   => sub {},
    list        => 'abracadabra',
} ); };
like($@, qr/^'list' element passed to constructor must be array ref/,
    "'list' argument must be an array ref");

eval { $lre  = List::RewriteElements->new ( {
    body_rule   => sub {},
    list        => {},
} ); };
like($@, qr/^'list' element passed to constructor must be array ref/,
    "'list' argument must be an array ref");

eval { $lre  = List::RewriteElements->new ( {
    body_rule   => sub {},
    list        => [],
    body_suppress   => 'abracadabra',
} ); };
like($@, qr/^'body_suppress' element passed to constructor must be code ref/,
    "'body_suppress' argument must be a code ref");

eval { $lre  = List::RewriteElements->new ( {
    body_rule   => sub {},
    list        => [],
    body_suppress   => {},
} ); };
like($@, qr/^'body_suppress' element passed to constructor must be code ref/,
    "'body_suppress' argument must be a code ref");

eval { $lre  = List::RewriteElements->new ( {
    body_rule   => sub {},
    list        => [],
    header_rule   => 'abracadabra',
} ); };
like($@, qr/^'header_rule' element passed to constructor must be code ref/,
    "'header_rule' argument must be a code ref");

eval { $lre  = List::RewriteElements->new ( {
    body_rule   => sub {},
    list        => [],
    header_rule   => {},
} ); };
like($@, qr/^'header_rule' element passed to constructor must be code ref/,
    "'header_rule' argument must be a code ref");

eval { $lre  = List::RewriteElements->new ( {
    body_rule   => sub {},
    list        => [],
    header_rule   => sub {},
    header_suppress   => 'abracadabra',
} ); };
like($@, qr/^'header_suppress' element passed to constructor must be code ref/,
    "'header_suppress' argument must be a code ref");

eval { $lre  = List::RewriteElements->new ( {
    body_rule   => sub {},
    list        => [],
    header_rule   => sub {},
    header_suppress   => {},
} ); };
like($@, qr/^'header_suppress' element passed to constructor must be code ref/,
    "'header_suppress' argument must be a code ref");

eval { $lre  = List::RewriteElements->new ( {
    body_rule   => sub {},
    list        => [],
    header_suppress   => sub {},
} ); };
like($@, qr/^If 'header_suppress' criterion is supplied, a 'header_rule' element must be supplied as well/,
    "'header_suppress' requires 'header_rule' as well");

