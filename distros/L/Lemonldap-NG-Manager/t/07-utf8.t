# Test if an UTF-8 char is well returned

use Test::More;
use strict;

my $str = "The LemonLDAP::NG team \x{c2}\x{a9}";

require 't/test-lib.pm';

my $href = &client->jsonResponse('/confs/1/cfgAuthor');

#binmode STDERR;

ok( $href->{value} eq $str, 'Value is well encoded' )
  or print STDERR "Expect '$href->{value}' eq '$str'";
count(1);

done_testing( count() );
