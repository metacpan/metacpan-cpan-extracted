package MOP4Import::Types::Extend;
use 5.010;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use MOP4Import::Opts qw/Opts m4i_opts/;
use MOP4Import::Types -as_base;
use MOP4Import::Util;

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

sub import {
  my $myPack = shift;

  m4i_log_start() if DEBUG;

  my Opts $opts = m4i_opts([caller])->take_hash_maybe(\@_);

  $opts->{extending} = 1;

  $myPack->dispatch_pairs_as_declare(type => $opts, @_);

  m4i_log_end($opts->{callpack}) if DEBUG;
}

1;
