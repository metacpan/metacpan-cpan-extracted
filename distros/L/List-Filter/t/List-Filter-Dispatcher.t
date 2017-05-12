# Test file created outside of h2xs framework.
# Run this like so: `perl List-Filter-Dispatcher.t'
#   doom@kzsu.stanford.edu     2007/04/26 21:50:00

use warnings;
use strict;
$|=1;
my $DEBUG = 0;
use Data::Dumper;

use Test::More;
BEGIN { plan tests => 3 };

use FindBin qw($Bin);

use lib "$Bin/../../..", "$Bin/dat/lib";
use List::Filter;

# This should match the "use lib" value above
my $test_lib = "$Bin/dat/lib";

BEGIN {
  use_ok( 'List::Filter::Dispatcher' );
}

ok(1, "Traditional: If we made it this far, we're ok.");

($DEBUG) && print STDERR "test_lib: $test_lib\n";


my $plugin_root = 'Nada';
my $plugin_exceptions = [ 'Nada::Zero' ];


use List::Filter::Dispatcher;

my $dispatcher =
  List::Filter::Dispatcher->new(
                                { plugin_root   => $plugin_root,
                                  exceptions    => $plugin_exceptions,
                                } );


{#5
  my $testname = "applying a filter method from a plugin via the dispatcher";

  my $filter =
    List::Filter->new(
                               { name              => 'skip_boring_stuff',
                                 terms             => ['\.vb$', '\.js$'],
                                 method            => 'skip',
                                 description       => "Skip the really boring stuff",
                                 modifiers         => "i",
                                 plugin_root       => $plugin_root,
                                 plugin_exceptions => $plugin_exceptions,
                               } );

  my $aref_in = [ qw(
                    blah.vb
                    bah.js
                    real_stuff.pl
                    GoodStuff.pm
                    fergetit.vb
                    okay.txt
                    README.not
                 ) ];

  my $aref_out = $dispatcher->apply( $filter, $aref_in );

  my @expected = sort( (
                        'real_stuff.pl',
                        'GoodStuff.pm',
                        'okay.txt',
                        'README.not',
                      )
                     );


  my @result = sort @{ $aref_out };

  is_deeply( \@result, \@expected, "$testname");

}






