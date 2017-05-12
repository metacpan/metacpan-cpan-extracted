package MOP4Import::Pairs;
use 5.010;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use MOP4Import::Declare -as_base, qw/Opts/;
use MOP4Import::Util qw/terse_dump/;

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

sub dispatch_pairs_as {
  (my $myPack, my $pragma, my Opts $opts, my $callpack, my (@pairs)) = @_;

  if (@pairs and ref $pairs[0] eq 'CODE') {
    (shift @pairs)->($myPack, $opts, $callpack);
  }

  unless (@pairs % 2 == 0) {
    croak "Odd number of arguments!";
  }

  my $sub = $myPack->can("declare_$pragma")
    or croak "Unknown declare pragma: $pragma";

  while (my ($name, $speclist) = splice @pairs, 0, 2) {
    print STDERR " dispatching $pragma for pair("
      , terse_dump($name, $speclist), "\n" if DEBUG;

    $sub->($myPack, $opts, $callpack, $name, @$speclist);
  }
}

1;
