#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN { require_ok( 'LWP::Protocol::AnyEvent::http' ); }

diag( "Testing LWP::Protocol::AnyEvent::http $LWP::Protocol::AnyEvent::http::VERSION, Perl $]" );

eval { diag("Testing using AnyEvent backend " . AnyEvent::detect()); };

for (sort grep /\.pm\z/, keys %INC) {
   s/\.pm\z//;
   s!/!::!g;
   eval { diag(join(' ', $_, $_->VERSION || '<unknown>')) };
}
