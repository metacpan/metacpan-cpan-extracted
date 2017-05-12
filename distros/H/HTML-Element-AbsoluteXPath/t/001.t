use strict;
use lib qw(./lib);
use warnings;

use Test::More tests => 3;                      # last test to print

use_ok('HTML::Element' );
use_ok('HTML::Element::AbsoluteXPath');

my @has = grep{ $_ eq 'abs_xpath'  }keys %HTML::Element::;

ok( @has , 'has abs_xpath');

