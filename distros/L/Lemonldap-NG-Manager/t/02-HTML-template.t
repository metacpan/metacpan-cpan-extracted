# Verify just that '/' requests returns HTML and some elements

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
ok( $res->[2]->[0]        =~ m#<title>Demo Manager</title>#,
    'Instance name found in SPA title' )
  or print STDERR "Instance name" . Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m#title="Demo" src=#, 'Instance name found in title' )
  or print STDERR "Instance name" . Dumper( $res->[2]->[0] );
ok(
    $res->[2]->[0] =~
      m#<li><a href="https://lemonldap-ng.org/team.html">Demo</a></li>#,
    'Instance name found in li'
) or print STDERR "Instance name" . Dumper( $res->[2]->[0] );
count(7);

done_testing( count() );
