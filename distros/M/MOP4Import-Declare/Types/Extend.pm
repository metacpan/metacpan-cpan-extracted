package MOP4Import::Types::Extend;
use 5.010;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use MOP4Import::Types sub {
  my ($types, $opts, $mypack) = @_;

  $types->declare_as_base($opts, $mypack);

  $types->dispatch_import($opts, $mypack, qw/Opts/);
};

sub import {
  my $myPack = shift;

  my Opts $opts = Opts->new([caller])->take_hash_maybe(\@_);

  $opts->{extending} = 1;

  $myPack->dispatch_pairs_as(type => $opts, $opts->{destpkg}, @_);
}

1;
