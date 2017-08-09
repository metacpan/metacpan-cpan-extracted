package Test2::Plugin::FauxOS;

use strict;
use warnings;
use Test2::API qw/test2_add_callback_exit/;

sub import
{
  my(undef, $os) = @_;
  die "you must use Test2::Plugin::FauxOS prior to FFI::CheckLib" if $INC{'FFI/CheckLib.pm'};
  $FFI::CheckLib::os = $os;
  
  test2_add_callback_exit(sub {
    my ($ctx, $real, $new) = @_;
    
    $ctx->note("faux os: $os");
    $ctx->note("real os: $^O");
  });
}

1;
