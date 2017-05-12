package Log::Dump::Test::Loaded;

use strict;
use warnings;
use Log::Dump::Test::Class;
use Log::Dump;

sub new { bless {}, shift }

sub test_class  { 'Log::Dump::Test::Class' }
sub test_object { Log::Dump::Test::Class->new; }

1;
