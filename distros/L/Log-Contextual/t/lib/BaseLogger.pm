package BaseLogger;

use Log::Contextual ();
BEGIN { our @ISA = qw(Log::Contextual); }
use Log::Contextual::SimpleLogger;

my $logger = DumbLogger2->new;

sub arg_levels { $_[1] || [qw(lol wut zomg)] }
sub arg_logger { $_[1] || $logger }

sub router {
  our $Router_Instance ||= do {
    require Log::Contextual::Router;
    Log::Contextual::Router->new
  };
}

package DumbLogger2;

our $var;
sub new { bless {}, 'DumbLogger2' }
sub is_wut  { 1 }
sub wut     { $var = "[wut] $_[1]\n" }
sub is_lol  { 1 }
sub lol     { $var = "[lol] $_[1]\n" }
sub is_zomg { 1 }
sub zomg    { $var = "[zomg] $_[1]\n" }

1;
