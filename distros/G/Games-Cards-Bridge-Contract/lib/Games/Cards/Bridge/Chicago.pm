package Games::Cards::Bridge::Chicago;

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
	'NS_score',
	'EW_score',
	'NS_vul',	# bool
	'EW_vul',	# bool
	'complete',	# bool
	'dealer',	# N E S W
);

sub both_vul {
  my $self = shift;
  return $self->NS_vul && $self->EW_vul;
}

sub __hand_setup {
  my $self = shift;
  my $hands_played = scalar @{$self->contracts};
  my %states = (
    # num_played => [ dealer, NS_vul, EW_vul ]
    0 => [ 'N', 0, 0 ],
    1 => [ 'E', 1, 0 ],
    2 => [ 'S', 0, 1 ],
    3 => [ 'W', 1, 1 ],
  );
  my $state = $states{$hands_played} or do {
    $self->set('complete', 1);
    return 0;
  };
  $self->set('dealer', $state->[0]);
  $self->set('NS_vul', $state->[1]);
  $self->set('EW_vul', $state->[2]);
  return 1;
}

sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  $self = bless {}, $class;
  $self->set($_, 0) for qw/NS_score EW_score NS_vul EW_vul complete/;
  $self->set('contracts', []);
  $self->set('dealer', 'N');
  $self->__hand_setup();
  return $self;
}

sub contract {
  my $self = shift;
  my $p = {@_};
  my $NS = $p->{declarer} =~ /^[NS]$/;
  my $EW = !$NS;
  my $contract = Games::Cards::Bridge::Contract->new(
	declarer=> $p->{declarer},
	trump	=> $p->{trump},
	bid	=> $p->{bid},
	made	=> $p->{made},
	down	=> $p->{down},
	vul	=> ($NS ? $self->NS_vul : $self->EW_vul),
	penalty	=> $p->{dbl},
  );
  push @{$self->contracts}, $contract;
  my $score = $contract->duplicate_score;
  my $scoreProperty =
	($NS && $score>0) || ($EW && $score<0)
	? 'NS_score'
	: 'EW_score'
  ;
  $self->set($scoreProperty, $self->$scoreProperty + abs $score);
  $self->__hand_setup();
  return $contract;
}

1;


=pod

=head1 NAME

Games::Cards::Bridge::Chicago - Object for Bridge (card game) Chicago scoring

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This module provides a class for creating Bridge objects for a Chicago game (aka 'Four-Deal Bridge'), including the results and scoring and current state of the game.

  use Games::Cards::Bridge::Chicago;
  sub show_score {
    my $chi = shift;
    printf "NS = %d \t EW = %d\n", $chi->NS_score, $chi->EW_score;
    printf "  Vul:  NS = %d \t EW = %d\n", $chi->NS_vul, $chi->EW_vul;
    printf "==COMPLETE==\n" if $chi->complete;
  }
  my $chi = Games::Cards::Bridge::Chicago->new;

  show_score($chi);
  foreach my $opts (
    { declarer => 'N', trump => 'H', bid => '4', made => '4' },
    { declarer => 'S', trump => 'C', bid => '3', down => '2', dbl => 1 },
    { declarer => 'E', trump => 'N', bid => '3', made => '3' },
    { declarer => 'W', trump => 'D', bid => '5', down => '3' },
  ){
    $chi->contract( %$opts );
    show_score($chi);
  }


=head1 METHODS

=head2 new

No parameters needed.

=head2 contract

Add a contract to the game.  This needs the same arguments as L<Games::Cards::Bridge::Contract>'s constructor. This method is also responsible for internally updating the attributes. See also L<http://www.acbl.org/learn/scoreChicago.html>

=head2 both_vul

Alias to returns true iff ->we_vul() and ->they_vul().

=head1 ATTRIBUTES

These are all auto-calculated/maintained; their current values are available from the accessor method provided by L<Class::Accessor>.

=head2 contracts

Array ref holding all the contracts added by the contract() method.

=head2 NS_score

Gives the current total North-South score.

=head2 they_score

Gives the current total East-West score.

=head2 we_vul

Returns true if the North-South side is vulnerable.

=head2 they_vul

Returns true if the East-West side is vulnerable.

=head2 complete

Returns true if the game has concluded (played 4 hands).

=head2 dealer

Returns N E S or W representing the current dealer.

=head1 PREREQUISITES

=over 4

=item *

L<Class::Accessor>

=item *

L<Carp>

=item *

L<Games::Cards::Bridge::Contract>

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


