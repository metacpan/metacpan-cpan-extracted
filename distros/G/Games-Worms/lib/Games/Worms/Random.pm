# Time-stamp: "1999-03-03 20:02:20 MST" -*-Perl-*-
package Games::Worms::Random;
use strict;
use vars qw($Debug $VERSION @ISA);
use Games::Worms::Base;
@ISA = ('Games::Worms::Base');
$Debug = 0;
$VERSION = "0.60";


=head1 NAME

Games::Worms::Random -- random worms

=head1 SYNOPSIS

  perl -MGames::Worms -e worms -- -tTk Games::Worms::Random

=head1 DESCRIPTION

Worms in the class Games::Worms::Random are totally random -- they
move at random in whichever way they can, without regard to any rules
or past movement.

=cut


sub which_way { # figure out which direction to go in
  my($worm, $hash_r) = @_;
  my @dirs = keys %$hash_r;
  return $dirs[ rand(@dirs) ];
}

sub am_memoized { 0; }

1;

__END__

