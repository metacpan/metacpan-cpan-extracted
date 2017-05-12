# Time-stamp: "1999-03-03 20:11:21 MST" -*-Perl-*-
package Games::Worms::Random2;
use strict;
use vars qw($Debug $VERSION @ISA);
use Games::Worms::Random;
@ISA = ('Games::Worms::Random');
$Debug = 0;
$VERSION = "0.60";


=head1 NAME

Games::Worms::Random2 -- class for consistent random worms

=head1 SYNOPSIS

  perl -MGames::Worms -e worms -- -tTk Games::Worms::Random2

=head1 DESCRIPTION

Worms in the class Games::Worms::Random2 are random, but consistent --
that is, a worm in this class, upon meeting a new context, will choose
at random which way to go, and then will associate that context with
that move; and for the rest of its life, given that context, it will
move in that direction.

Games::Worms::Random2 is implemented by simply inheriting from
Games::Worms::Random, but setting memoization to true.

This simple change leads to worms that often behave rather like Beeler
worms, but sometimes behave astonishingly differently.

=cut

sub am_memoized { 1; }

1;

__END__
