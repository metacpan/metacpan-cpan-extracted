#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN { require_ok( 'LWP::Protocol::Coro::http' ); }

diag( "Testing LWP::Protocol::Coro::http $LWP::Protocol::Coro::http::VERSION, Perl $]" );

for (sort grep /\.pm\z/, keys %INC) {
   s/\.pm\z//;
   s!/!::!g;
   eval { diag(join(' ', $_, $_->VERSION || '<unknown>')) };
}
