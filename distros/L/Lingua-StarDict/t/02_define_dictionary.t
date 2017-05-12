# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-StarDict.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Lingua::StarDict') };

#########################


use strict;
my $translator = new Lingua::StarDict( dict => "/usr/share/stardict/dic/en-ru-bars.ifo" );
ok( ref $translator eq 'Lingua::StarDict', "create Lingua::StarDict object");


