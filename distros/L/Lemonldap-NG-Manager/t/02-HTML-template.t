# Verify just that '/' requests returns HTML

use Test::More;
use strict;

require 't/test-lib.pm';

my $res;

ok( $res = &client->_get('/'), 'Succeed to get /' );
my %hdrs = @{ $res->[1] };
ok( $res->[0] == 200, 'Return a 200 code' )
  or print STDERR "Received" . Dumper($res);
ok( $hdrs{'Content-Type'} =~ /text\/html$/i, 'Content is declared as HTML' );
ok( $res->[2]->[0]        =~ /<html/si,      'It contains a html tag' );

count(4);

done_testing( count() );

