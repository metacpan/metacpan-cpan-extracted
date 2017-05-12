package Games::Cards::Bridge::Rubber;

use strict;
use warnings;

use base qw(Class::Accessor);
use Games::Cards::Bridge::Contract;
use Carp;

our $VERSION = '0.01';

__PACKAGE__->mk_accessors(
	'contracts',	# array ref
	# these are all auto-calculated
	# scores:
	'we_above',
	'we_below',
	'we_leg',
	'they_leg',
	'they_above',
	'they_below',
	'we_vul',	# bool
	'they_vul',	# bool
	'complete',	# bool
);

sub we_score {
  my $self = shift;
  return $self->we_above + $self->we_below;
}
sub they_score {
  my $self = shift;
  return $self->they_above + $self->they_below;
}
sub both_vul {
  my $self = shift;
  return $self->we_vul && $self->they_vul;
}

sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  $self = bless {}, $class;
  $self->set($_, 0) for qw/we_above we_below they_above they_below we_vul they_vul complete we_leg they_leg/;
  $self->set('contracts', []);
  return $self;
}

sub contract {
  my $self = shift;
  my $p = {@_};
  my $dir = lc $p->{direction};
  my $we = $dir eq 'we';
  my $they = !$we;
  croak "'direction' must be 'we' or 'they'" unless $dir =~ /^(we|they)$/;
  my $contract = Games::Cards::Bridge::Contract->new(
	declarer=> 'N',
	trump	=> $p->{trump},
	bid	=> $p->{bid},
	made	=> $p->{made},
	down	=> $p->{down},
	vul	=> ($we ? $self->we_vul : $self->they_vul),
	penalty	=> $p->{dbl},
  );
  my @score = $contract->rubber_score;  # (declarer_above, declarer_below, opps_above)
  push @{$self->contracts}, $contract;
  my (    $decAbove,	$decBelow,	$decLeg,	$decVul,	$oppAbove,	$oppLeg,	$oppVul ) = $we
    ? qw/ we_above	we_below	we_leg		we_vul		they_above	they_leg	they_vul /
    : qw/ they_above	they_below	they_leg	they_vul	we_above	we_leg		we_vul   / ;
  $self->set($decAbove, $self->$decAbove + $score[0]);
  $self->set($decBelow, $self->$decBelow + $score[1]);
  $self->set($oppAbove, $self->$oppAbove + $score[2]);
  $self->set($decLeg, $self->$decLeg + $score[1]);
  if( $self->$decLeg >= 100 ){	# game was reached
    $self->set($decLeg, 0);	# clear the legs
    $self->set($oppLeg, 0);
    if( $self->$decVul ){	# if already vul
      $self->set('complete', 1);	# .. then this was second game, so rubber is done
      $self->set($decAbove, $self->$decAbove + ($self->$oppVul ? 500 : 700) );  # rubber bonus
    }else{
      $self->set($decVul, 1);	# now vul
    }
  }
  return $contract;
}

1;


=pod

=head1 NAME

Games::Cards::Bridge::Rubber - Object for Bridge (card game) Rubber scoring

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This module provides a class for creating Bridge rubber objects, including the results and scoring and current state of the rubber.

  use Games::Cards::Bridge::Rubber;
  sub show_score {
    my $rubber = shift;
    printf "Totals (above/below): We = %d/%d \t They = %d/%d\n", $rubber->we_above, $rubber->we_below, $rubber->they_above, $rubber->they_below; 
    printf "  Legs:  We = %d \t They = %d\n", $rubber->we_leg, $rubber->they_leg;
    printf "  Vul:  We = %d \t They = %d\n", $rubber->we_vul, $rubber->they_vul;
    printf "==COMPLETE==\n\tWe: %d\tThey: %d\n", $rubber->we_score, $rubber->they_score if $rubber->complete;
  }
  my $rubber = Games::Cards::Bridge::Rubber->new;

  show_score($rubber);
  foreach my $opts (
    { direction => 'we', trump => 'H', bid => '2', made => '4' },
    { direction => 'they', trump => 'S', bid => '4', down => '2', dbl => 1 },
    { direction => 'they', trump => 'N', bid => '3', made => '4' },
    { direction => 'they', trump => 'S', bid => '3', made => '3' },
    { direction => 'they', trump => 'D', bid => '2', down => '2'  },
    { direction => 'we', trump => 'H', bid => '6', made => '7', dbl => 1 },
    { direction => 'they', trump => 'N', bid => '1', made => '2' },
    { direction => 'we', trump => 'C', bid => '3', made => '3' },
    { direction => 'they', trump => 'H', bid => '3', made => '3' },
  ){
    $rubber->contract( %$opts );
    show_score($rubber);
  }


=head1 METHODS

=head2 new

No parameters needed.

=head2 contract

Add a contract to the rubber.
This needs the same arguments as L<Games::Cards::Bridge::Contract>'s constructor, as well as a I<direction> parameter of 'we' or 'they' (and the I<declarer> parameter is not used).
This method is also responsible for internally updating the attributes.
See also L<http://www.acbl.org/learn/scoreRubber.html>

=head2 we_score

Gives the current total 'We' score.

=head2 they_score

Gives the current total 'They' score.

=head2 both_vul

Alias to returns true iff ->we_vul() and ->they_vul().

=head1 ATTRIBUTES

These are all auto-calculated/maintained; their current values are available from the accessor method provided by L<Class::Accessor>.

=head2 contracts

Array ref holding all the contracts added by the contract() method.

=head2 we_above

Current above-the-line score for 'We'.

=head2 we_below

Current below-the-line score for 'We'.

=head2 we_leg

The current "leg" for 'We'.

=head2 they_leg

The current "leg" for 'They'.

=head2 they_above

Current above-the-line score for 'They'.

=head2 they_below

Current below-the-line score for 'They'.

=head2 we_vul

Returns true if the 'We' side is vulnerable (has one "game").

=head2 they_vul

Returns true if the 'They' side is vulnerable (has one "game").

=head2 complete

Returns true if the rubber has concluded (one side got two "games").

=head1 PREREQUISITES

=over 4

=item *

L<Class::Accessor>

=item *

L<Carp>

=item *

L<Games::Cards::Bridge::Contract>

=back

=head1 TODO

=over 4

=item *

Handle honors bonuses

=back

=head1 AUTHOR

David Westbrook, C<< <dwestbrook at gmail.com> >>

=head1 BUGS & SUPPORT

See L<Games::Cards::Bridge::Contract>

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


