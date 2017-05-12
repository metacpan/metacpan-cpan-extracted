package Util;
use strict;
use warnings;

use Test::More;

use Exporter 'import';
our @EXPORT = qw{
  test_on_initialize
  test_on_initialize_count
  test_after_initialize
  test_after_initialize_count
};

use constant 'test_on_initialize_count' => 3;
sub test_on_initialize{
  my( $package, $default, $init, $full ) = @_;
  $full = $init unless defined $full;

  my $initquote = defined $init ? qq["$init"] : 'undef';
  my $fullquote = defined $init ? qq["$full"] : 'undef';

  note  qq[initialize agent to $initquote];
  no warnings 'uninitialized';

  note qq[$package->new( agent => $initquote )];
  my $rpc = $package->new( (agent => $init) x defined $init );

  is $rpc->agent,       $full, 'rpc->agent';
  is $rpc->ua->agent.'', $full, 'rpc->ua->agent';
  is $rpc->marshal->user_agent, $full, 'rpc->marshal->user_agent';
}

use constant 'test_after_initialize_count' => 4;
sub test_after_initialize{
  my( $package, $default, $init, $full ) = @_;
  $full = $init unless defined $full;

  my $initquote = defined $init ? qq["$init"] : 'undef';
  my $fullquote = defined $init ? qq["$full"] : 'undef';

  note  qq[set agent to $initquote after initialization];
  no warnings 'uninitialized';

  note qq[$package->new()];
  my $rpc = $package->new();

  is $rpc->agent, $default, 'initialized with default';
  note qq[rpc->agent( $initquote )];
  $rpc->agent($init);

  is $rpc->agent,        $full, 'rpc->agent';
  is $rpc->ua->agent.'', $full, 'rpc->ua->agent';
  is $rpc->marshal->user_agent, $full, 'rpc->marshal->user_agent';
}

1;
