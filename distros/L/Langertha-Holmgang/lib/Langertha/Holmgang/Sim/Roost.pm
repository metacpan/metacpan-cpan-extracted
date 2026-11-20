package Langertha::Holmgang::Sim::Roost;
# ABSTRACT: The answer world roost — an invented dragon roost with perches and a larder, for the example suite demo-roost

use Moose;
use namespace::autoclean;

with 'Langertha::Holmgang::Role::AnswerWorld';

our $VERSION = '0.002';


our %TOOLS = (
  survey_roost => [],
  feed_dragon  => [qw( dragon food )],
  move_dragon  => [qw( dragon perch )],
);

#### Plugin contract

sub device_type { 'roost' }


sub tools { return \%TOOLS }


sub tool {
  my ( $self, $roost, $name, $args, $ctx ) = @_;
  $name //= '';
  my $code = $TOOLS{$name} && $self->can( '_t_'.$name )
    or return ( "Error: unknown tool '".$name."'.", 0 );
  return $self->$code( $roost, $args || {} );
}


#### State

# the key of a hash entry, matched without case and surrounding white space
sub _key {
  my ( $self, $h, $want ) = @_;
  return undef unless ref $h eq 'HASH' && defined $want && !ref $want;
  ( my $w = lc $want ) =~ s/\A\s+|\s+\z//g;
  my ($k) = grep { lc $_ eq $w } sort keys %$h;
  return $k;
}

sub _given {
  my ( $self, $v ) = @_;
  return defined $v && !ref $v ? $v : '';
}

sub _baskets {
  my ( $self, $n ) = @_;
  return $n.' basket'.( $n == 1 ? '' : 's' );
}

sub _list {
  my ( $self, $l ) = @_;
  my @l = ref $l eq 'ARRAY' ? @$l : ();
  return @l ? join( ', ', @l ) : 'none';
}

#### Tools

sub _t_survey_roost {
  my ( $self, $r ) = @_;
  my $d = ref $r->{dragons} eq 'HASH' ? $r->{dragons} : {};
  my $p = ref $r->{perches} eq 'HASH' ? $r->{perches} : {};
  my $l = ref $r->{larder}  eq 'HASH' ? $r->{larder}  : {};
  my %on = map { defined $d->{$_}{perch} ? ( $d->{$_}{perch} => $_ ) : () } keys %$d;
  my @out = ('Dragons:');
  push @out, map {
    my $x = $d->{$_};
    '- '.$_.': wingspan '.( $x->{wingspan} // '?' ).', perch '.( $x->{perch} // 'none' )
      .', eats '.$self->_list( $x->{eats} ).', meals '.$self->_list( $x->{meals} );
  } sort keys %$d;
  push @out, '- none' unless %$d;
  push @out, 'Perches:';
  push @out, map { '- '.$_.': span '.( $p->{$_}{span} // '?' ).', '.( $on{$_} // 'free' ) } sort keys %$p;
  push @out, '- none' unless %$p;
  push @out, 'Larder:';
  push @out, map { '- '.$_.': '.$self->_baskets( $l->{$_} ) } sort keys %$l;
  push @out, '- empty' unless %$l;
  return ( join( "\n", @out ), 1 );
}

sub _t_feed_dragon {
  my ( $self, $r, $a ) = @_;
  my $dk = $self->_key( $r->{dragons}, $a->{dragon} )
    or return ( "Error: there is no dragon called '".$self->_given( $a->{dragon} )."'.", 0 );
  my $fk = $self->_key( $r->{larder}, $a->{food} )
    or return ( "Error: the larder has no '".$self->_given( $a->{food} )."'.", 0 );
  return ( 'Error: no '.$fk.' left in the larder.', 0 ) unless $r->{larder}{$fk} > 0;
  $r->{larder}{$fk}--;
  my $dragon = $r->{dragons}{$dk};
  $dragon->{meals} = [] unless ref $dragon->{meals} eq 'ARRAY';
  push @{ $dragon->{meals} }, $fk;
  return ( $dk.' ate a basket of '.$fk.'. Left in the larder: '.$self->_baskets( $r->{larder}{$fk} ).'.', 1 );
}

sub _t_move_dragon {
  my ( $self, $r, $a ) = @_;
  my $dk = $self->_key( $r->{dragons}, $a->{dragon} )
    or return ( "Error: there is no dragon called '".$self->_given( $a->{dragon} )."'.", 0 );
  my $pk = $self->_key( $r->{perches}, $a->{perch} )
    or return ( "Error: there is no perch called '".$self->_given( $a->{perch} )."'.", 0 );
  my $dragon = $r->{dragons}{$dk};
  return ( $dk.' is already on '.$pk.'.', 1 ) if ( $dragon->{perch} // '' ) eq $pk;
  my ($other) = grep { $_ ne $dk && ( $r->{dragons}{$_}{perch} // '' ) eq $pk } sort keys %{ $r->{dragons} };
  return ( 'Error: '.$pk.' is taken by '.$other.'.', 0 ) if defined $other;
  $dragon->{perch} = $pk;
  return ( $dk.' flew to '.$pk.'.', 1 );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Roost - The answer world roost — an invented dragon roost with perches and a larder, for the example suite demo-roost

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # suite.yaml: every tool names the world, the tool's name picks what it does
  tools:
    - { name: feed_dragon, simulator: roost, description: …, parameters: { … required: [ dragon, food ] } }

  my $sims = Langertha::Holmgang::Simulators->new;
  my ( $output, $ok ) = $sims->tool_call( $state, roost => feed_dragon => { dragon => 'ember', food => 'peppers' } );

=head1 DESCRIPTION

A world without a device (contract: L<Langertha::Holmgang::Role::AnswerWorld>;
type C<roost>): a B<dragon roost>, freely invented for the example suite
C<demo-roost> — dragons that sit on perches and eat from a larder. It models
nothing that exists and is there to show the shape of a typed answer world.
Tool names, parameters and world keys are English:

  survey_roost  { }                 the dragons, the perches and the larder
  feed_dragon   { dragon, food }    one basket of a food from the larder to a dragon
  move_dragon   { dragon, perch }   a dragon flies to another perch

Names are matched without regard to case and surrounding white space. A call
the world refuses answers C<Error: …> and changes nothing.

=over 4

=item C<feed_dragon>

Takes one basket of C<food> out of the larder and adds the food to the
dragon's C<meals>. Refused when there is no such dragon, when the larder has
no such food, or when none of it is left. The world does not judge the
meal: a dragon eats what it is given, whether or not it is in its C<eats>.

=item C<move_dragon>

Sets the dragon's C<perch>. Refused when there is no such dragon or perch, or
when another dragon sits on the perch (one dragon per perch). The world does
not compare C<wingspan> and C<span>: a dragon flies to a perch too small for
it all the same.

=back

=head2 State

  roost:
    type: roost
    dragons:
      ember: { wingspan: 14, perch: north-crag, eats: [ coal, peppers ], meals: [] }
    perches:
      north-crag: { span: 20 }
    larder:
      peppers: 2        # baskets

C<dragons> by name: C<wingspan> (a number), C<perch> (a key of C<perches>, or
absent for a dragon on the ground), C<eats> (the foods it likes, for the
survey and for a case's rules; the tools do not read it), C<meals> (the foods
it was given, in order; absent counts as none). C<perches> by name: C<span>,
the widest wingspan the perch holds (shown, not enforced). C<larder>: food
name to a whole number of baskets.

Only the state, deterministic, neutral.

=head2 device_type

C<roost>.

=head2 tools

  my $tools = $world->tools;   # { feed_dragon => [qw( dragon food )], … }

The tools of this world with their required parameters (for the loader).

=head2 tool

  my ( $output, $ok ) = $world->tool( $roost, $name, \%args, $ctx );

A tool call on the state of the roost (C<$roost> is changed). A name not in
L</tools> is an error.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
