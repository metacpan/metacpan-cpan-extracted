package MOP4Import::Types;
use 5.010;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use MOP4Import::Pairs -as_base, qw/Opts m4i_opts/;
# XXX: [carp_not => MOP4Import::Util]
use MOP4Import::Declare::Type -as_base;
use MOP4Import::Util;

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

sub import {
  my $myPack = shift;

  m4i_log_start() if DEBUG;

  my Opts $opts = m4i_opts([caller])->take_hash_maybe(\@_);

  $myPack->dispatch_pairs_as_declare(type => $opts, @_);

  my $tasks;
  if ($tasks = $opts->{delayed_tasks} and @$tasks) {
    print STDERR " Calling delayed tasks for $opts->{destpkg}\n" if DEBUG;
    $_->($opts) for @$tasks;
  }

  m4i_log_end($opts->{callpack}) if DEBUG;
}

1;
