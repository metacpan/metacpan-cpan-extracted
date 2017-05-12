use warnings;
use strict;

use Test::More;

use JSON::RPC::LWP;
my $package = 'JSON::RPC::LWP';
my $dist    = 'JSON-RPC-LWP';
my $version = $JSON::RPC::LWP::VERSION;
my $default = "JSON-RPC-LWP/$version";

use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin,'lib');

use Util;

# [ $agent_in, $agent_full ],
my @test = (
  [ undef, $default ],
  [ 'testing' ],
  [ '' ],
  [ ' ', " $default" ],
  [ 'testing ', "testing $default" ],
  [ $default ],
  [ $package ],
  [ $dist ],
);

my $init_count = test_on_initialize_count + test_after_initialize_count;
plan tests => 2 + @test * $init_count;

{
  my $rpc = JSON::RPC::LWP->new( _agent => 'anything' );
  is $rpc->_agent,     $default, '_agent is initialized correctly';
}

{
  my $rpc = JSON::RPC::LWP->new;
  is $rpc->agent,      $default, 'Default agent';
}

for my $test (@test){
  my($init,$full) = @$test;

  test_on_initialize(    $package, $default, $init, $full );
  test_after_initialize( $package, $default, $init, $full );
}
