package Games::Cards::Bridge::Contract;

use strict;
use warnings;
use base qw(Class::Accessor);
use Carp;

our $VERSION = '0.02';

__PACKAGE__->mk_accessors(
	'declarer',	# N E S W
	'trump',	# C D H S N P
	'vul',		# boolean
	'penalty',	# 0=none 1=X 2=XX
	'bid',		# 1..7
	'made',		# bid..7	undef
	'down',		# undef		1..bid
);

sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  my $p = { @_ };
  my $obj = bless {}, $class;
  while( my($k,$v) = each %$p ){
    next unless $obj->can($k);
    $obj->set($k, $v);
  }
  $obj->set('vul', $obj->vul ? 1 : 0 );  # force boolean
  $obj->set('penalty', 0 ) if ! $obj->penalty;  # force 0 for false
  $obj->__validate;
  return $obj;
}

sub __validate {
  my $self = shift;
  return if $self->trump eq 'P';
  croak 'declarer must be one of (N,E,S,W)' unless $self->declarer =~ /^[NESW]$/;
  croak 'trump must be one of (C,D,H,S,N,P)' unless $self->trump =~ /^[CDHSN]$/;
  croak 'vul must be true or false' unless $self->vul =~ /^[01]$/;
  croak 'penalty must be one of (0,1,2)' unless $self->penalty =~ /^[012]$/;
  croak 'bid must be one of (1..7)' unless $self->bid =~ /^[1234567]$/;
  if( defined $self->made ){
    croak 'made must be one of (1..7) and >= bid' unless $self->made =~ /^[1234567]$/ && $self->made >= $self->bid;
    croak 'down must be unset' if defined $self->down;
  }else{
    croak 'down must be one of (1..13) and <= bid+6' unless $self->down =~ /^([123456789]|1[0123])$/ && $self->down <= $self->bid + 6;
    croak 'made must be unset' if defined $self->made;
  }
}

sub minor { return shift->trump =~ /^[CD]$/ ? 1 : 0; }
sub major { return shift->trump =~ /^[HS]$/ ? 1 : 0; }
sub notrump { return shift->trump eq 'N' ? 1 : 0; }
sub passout { return shift->trump eq 'P' ? 1 : 0; }
sub slam { return shift->bid >= 6 ? 1 : 0; }
sub small_slam { return shift->bid == 6 ? 1 : 0; }
sub grand_slam { return shift->bid == 7 ? 1 : 0; }
sub game {
  my $self = shift;
  my $tricks = shift;
  $tricks = $self->bid unless defined $tricks;
  return $tricks >= 3 && ($self->notrump || ($self->major && $tricks >= 4) || ($self->minor && $tricks >= 5));
}
sub overtricks {
  my $self = shift;
  return unless $self->made;
  return $self->made - $self->bid;
}

sub rubber_score {
  my $self = shift;
  my $score = $self->__calc_score;
  return ( $score->{overtricks} + $score->{slam} + $score->{insult},  $score->{tricks},  $score->{undertricks} );
}

sub duplicate_score {
  my $self = shift;
  my $score = $self->__calc_score;
  return $score->{tricks} + $score->{overtricks} + $score->{partscore} + $score->{game} + $score->{slam} + $score->{insult} - $score->{undertricks};
}

sub __calc_score {
  my $self = shift;
  my %score = map { $_ => 0 } qw/ undertricks tricks overtricks partscore game slam insult /;
  if( $self->passout ){
    # do nothing
  }elsif( $self->made ){
    my ($n, $over) = ($self->bid, $self->overtricks);
    my ($minor, $major, $nt) = ($self->minor, $self->major, $self->notrump);
    $score{tricks} += 30*$n+10 if $nt;				# notrump: 40 first, 30 each after
    $score{tricks} += 30*$n if $major;				# major: 30 each
    $score{tricks} += 20*$n if $minor;				# minor: 20 each
    $score{tricks} *= 2*$self->penalty if $self->penalty;	# multiply 2x or 4x if X or XX
    $n *= 2*$self->penalty if $self->penalty;		# change the effective tricks based on X/XX
    if( $self->game($n) ){
      $score{game} += $self->vul ?  500 :  300;			# game bonus
    }else{
      $score{partscore} += 50;					# partscore bonus
    }
    if( $self->grand_slam ){
      $score{slam} += ($self->vul ? 1500 : 1000);		# grand slam bonus
    }elsif( $self->small_slam ){
      $score{slam} += ($self->vul ?  750 :  500);		# small slam bonus
    }
    if( $self->penalty ){
      $score{overtricks} += $over * 100 * $self->penalty * ($self->vul?2:1);  # overtricks: 100 each; x2/x4 for X/XX; x2 for vul
      $score{insult} += 50*$self->penalty;			# plus 50 or 100 for X or XX
    }else{
      $score{overtricks} += $over * ($minor ? 20 : 30);		# minor/major/notrump: 20/30/30 per overtrick
    }
  }else{  #down
    my $n = $self->down;
    if( ! $self->penalty ){
      $score{undertricks} += $n * ( $self->vul ? 100 : 50 );
    }else{
      if( $self->vul ){
        $score{undertricks} += 300*$n-100;
      }else{
        $score{undertricks} += 300*$n-400 + ($n==1?200:0) + ($n==2?100:0);
      }
      $score{undertricks} *= $self->penalty; # x2 if XX
    }
  }
  return \%score;
}

1;
__END__

=pod

=head1 NAME

Games::Cards::Bridge::Contract - Bridge (card game) contract and scoring class

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This module provides a class for creating Bridge contract objects, including the results and both duplicate and rubber scoring.

This is example is for the contract of 4S by North, not vulnerable, redoubled, and taking 11 tricks.

  my $contract = Games::Cards::Bridge::Contract->new( declarer=>'N', trump=>'S', bid=>4, made=>5, vul=>0, penalty=>2);
  my $pts = $contract->duplicate_score;
  my ( $declarer_above_line, $declarer_below_line, $defense_above_line ) = $contract->rubber_score;

=head1 METHODS

=head2 new

Requires named parameters L<trump>, L<declarer>, L<bid>, L<made>, L<down> (only one of I<made> or I<down> can be set). Optional named parameters of L<vul>, L<penalty>. See each of the L<ATTRIBUTES> for the allowed values/defaults.  Croaks if validation fails.

=head2 minor

Boolean -- true iff the contract is Clubs or Diamonds

=head2 major

Boolean -- true iff the contract is Hearts or Spades

=head2 notrump

Boolean -- true iff the contract is No Trump

=head2 passout

Boolean -- true iff the contract was a passout

=head2 slam

Boolean -- true iff contract was at the slam (small or grand) level

=head2 small_slam

Boolean -- true iff contract was a small slam (bid 6)

=head2 grand_slam

Boolean -- true iff contract was a grand slam (bid 7)

=head2 overtricks

If contract made, this is the number of overtrcks (made-bid).  undef if contract was defeated.

=head2 game

Boolean -- true iff the given number of tricks (defaults to number bid) would constitute the game level (or higher).

=head2 rubber_score

Returns an array of ( declarer_above, declarer_below, defense_above ) for the current contract/result.

Note that honors, game bonus, and rubber bonus need to be handled externally. (See L<Games::Cards::Bridge::Rubber>)

=head2 duplicate_score

Returns the declarer's score for this contract/result.  Postive if declarer made it, negative if he went down.

=head2 __calc_score

Internal-use method that does the actual score calculation. Returns a hashref w/the following keys:

=over 2

=item *

undertricks

=item *

tricks

=item *

overtricks

=item *

partscore

=item *

game

=item *

slam

=item *

insult

=back

each representing part of the total score. For scoring references/details, see

=over 4

=item *

L<http://www.acbl.org/learn/scoreRubber.html>

=item *

L<http://www.acbl.org/learn/scoreDuplicate.html>

=back

=head1 ATTRIBUTES

These all have accessors provided by L<Class::Accessor>.

=head2 declarer

Must be one of: N E S W for North, East, South, West.

=head2 trump

Must be one of: C D H S N P for Clubs, Diamonds, Hearts, Spades, Notrump, Passout.

=head2 vul

Boolean (gets casted into 1 or 0)

=head2 penalty

Must be 1 if the contract is doubled, 2 if it is redoubled, and 0 otherwise.

=head2 bid

The level of the contract. Must be between 1 and 7, inclusive.

=head2 made

If the contract made, this should be the level that was made, which must be between I<bid> and 7, inclusive. e.g. If bid 4 and took 12 tricks, then I<made> is 6.  Must be undef/unspecified if the contract went down.

=head2 down

If the contract was defeated, then this is number of tricks it went down, which must be between 1 and I<bid>, inclusive. e.g. If bid 4 and took 8 tricks, then I<down> is 2. Must be undef/unspecified if the contract made.

=head1 PREREQUISITES

=over 4

=item *

L<Class::Accessor>

=item *

L<Carp>

=back

=head1 AUTHOR

David Westbrook, C<< <dwestbrook at gmail.com> >>

=head1 SEE ALSO

=over 4

=item *

L<Games::Cards::Bridge::Rubber>

=back

=head1 TODO

=over 4

=item *

Honors & game/rubber bonus for Rubber bridge. (See L<Games::Cards::Bridge::Rubber>)

=item *

Release a Games::Cards::Bridge module

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-cards-bridge at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Cards-Bridge-Contract>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I'm also available by email or via '/msg davidrw' on L<http://perlmonks.org>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Cards::Bridge::Contract

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Cards-Bridge-Contract>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Cards-Bridge-Contract>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Cards-Bridge-Contract>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Cards-Bridge-Contract>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

