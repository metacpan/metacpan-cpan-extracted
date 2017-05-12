#-*- mode: perl;-*-

use strict;

use Test::More tests => 5;
use Test::Warn;

use Win32;

BEGIN {
#  ok( Win32::IsWinNT(), "Win32::IsWinNT?" );

  use_ok('Win32::EventLog');
  use_ok('Log::Dispatch');
  use_ok('Log::Dispatch::Win32EventLog');
}

{
  my $source = "\\foo\\bar";

  my $dispatch = Log::Dispatch->new;
  ok( defined $dispatch, "new Log::Dispatch" );

  warning_like {
    $dispatch->add( Log::Dispatch::Win32EventLog->new(
      source    => $source,
      min_level => 0, max_level => 7, name => 'test'
    ));
  } qr/Backslashes in source removed/, "Should complain about backslashes";


}
