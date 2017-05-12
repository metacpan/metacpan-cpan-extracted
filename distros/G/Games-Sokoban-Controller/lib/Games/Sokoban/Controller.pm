package Games::Sokoban::Controller;

use strict;
use warnings;
use Games::Sokoban;

our $VERSION = '0.01';

sub new {
  my $class = shift;
  bless { model => Games::Sokoban->new, @_ }, $class;
}

sub set_data {
  my ($self, $data, $format) = @_;
  $self->{model}->data($data, $format);
  $self->{level_id} = $self->{model}->normalise;
  $self->{model}->data($data, $format);
  $self->reset;
}

sub level_id { shift->{level_id} }

sub reset {
  my $self = shift;
  my $model = $self->{model};
  $self->{data} = $model->data;
  $self->{size} = [$model->{w}, $model->{h}];
  $self->{pos}  = [$model->start];
  $self->{replaced} = [];
  $self->{step} = 0;
}

sub size   { @{shift->{size}} }
sub width  { shift->{size}[0] }
sub height { shift->{size}[1] }

sub get {
  my ($self, $pos) = @_;
  substr($self->{data}, $self->_pos($pos), 1);
}

sub _rel {
  my ($self, $rel_pos) = @_;
  $rel_pos->[0] += $self->{pos}[0];
  $rel_pos->[1] += $self->{pos}[1];
  $self->get($rel_pos);
}

sub _replace {
  my ($self, $pos, $char) = @_;
  $pos->[0] += $self->{pos}[0];
  $pos->[1] += $self->{pos}[1];
  substr($self->{data}, $self->_pos($pos), 1, $char);
  push @{$self->{replaced}}, $pos;
}

sub _pos {
  my ($self, $pos) = @_;
  my ($x, $y) = @$pos;
  my ($w, $h) = @{$self->{size}};
  if ($x < 0)   { $x = 0; }
  if ($y < 0)   { $y = 0; }
  if ($x >= $w) { $x = $w - 1; }
  if ($y >= $h) { $y = $h - 1; }
  $x + $y * ($w + 1);  # +1 for "\n"
}

sub _dump {
  my $self = shift;
  my $data = $self->{data};
  my $left = $data =~ /([\.\+])/;
  my $done = $data =~ /(\*)/;
  my $dump = join "",
      $data, "\n",
      "pos: (", $self->{pos}[0], ", ", $self->{pos}[1], ")\n",
      "step: ", $self->{step}, "\n",
      "left: ", ($left || 0), "\n",
      "done: ", ($done || 0), "\n";

  if (defined wantarray) {
    return $dump;
  }
  else {
    print STDERR "\n", $dump;
  }
}

sub _move {
  my ($self, $delta, $direction) = @_;

  my ($x, $y) = @{$self->{pos}};
  my ($dx, $dy) = @$delta;
  my $me   = $self->_rel([0, 0]);
  my $dest = $self->_rel([$dx, $dy]);

  $self->{direction} = $direction;
  @{$self->{replaced}} = ();

  my $moved;
  if ($dest eq ' ' or $dest eq '.') {
    $self->_replace([0, 0] => ($me eq '@' ? ' ' : '.'));
    $self->_replace([$dx, $dy] => ($dest eq ' ' ? '@' : '+'));
    $moved = 1;
  }
  elsif ($dest eq '$' or $dest eq '*') {
    my $next = $self->_rel([$dx * 2, $dy * 2]);
    if ($next eq ' ' or $next eq '.') {
      $self->_replace([0, 0] => ($me eq '@' ? ' ' : '.'));
      $self->_replace([$dx, $dy] => ($dest eq '$' ? '@' : '+'));
      $self->_replace([$dx * 2, $dy * 2] => ($next eq ' ' ? '$' : '*'));
      $moved = 1;
    }
    else {
      $self->_debug("blocked");
    }
  }
  else {
    $self->_debug("wall");
  }
  if ($moved) {
    $self->{step}++;
    $self->{pos} = [$x + $dx, $y + $dy];
    return @{$self->{replaced}};
  }
  return;
}

sub go_right { shift->_move([1, 0], 'right') }
sub go_left  { shift->_move([-1, 0], 'left') }
sub go_up    { shift->_move([0, -1], 'up') }
sub go_down  { shift->_move([0, 1], 'down') }

sub direction { shift->{direction} || 'left' }

sub solved {
  my $self = shift;
  my $left = $self->{data} =~ /([\.\+\$])/;
  !$left;
}

sub _debug {
  my $self = shift;
  print STDERR @_, "\n" if $self->{debug};
}

1;

__END__

=head1 NAME

Games::Sokoban::Controller - sokoban controller

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Games::Sokoban::Controller;

  my $c = Games::Sokoban::Controller->new;
  $c->set_data(<<'LEVEL');
  #######
  #@ .  #
  #  $  #
  #     #
  #######
  LEVEL

  my @replaced = $c->go_down;

  for (@replaced) {
    my $char = $c->get($_->[0], $_->[1]);
    if ($char eq '@') { ... } # me
    if ($char eq '+') { ... } # me on a goal
    if ($char eq '$') { ... } # box
    if ($char eq '*') { ... } # box on a goal
    if ($char eq '.') { ... } # goal
    if ($char eq ' ') { ... } # floor
  }

  if ($c->solved) {
    print "SOLVED!\n";
  }

=head1 DESCRIPTION

This is a plain Sokoban controller. If you want to play Sokoban, you'll need some front-end.

=head1 METHODS

=head2 new

creates an object.

=head2 set_data (data, format)

set puzzle data (level). See L<Games::Sokoban> for available formats.

=head2 level_id

returns an unique id of the puzzle.

=head2 reset

(re-)initializes the puzzle.

=head2 size, width, height

return width and/or height of the puzzle.

=head2 get (x, y)

returns a character of the (0-based) coordinate.

=head2 go_left, go_right, go_up, go_down

move the player (and a box if applicable), and return an array of coordinates where you need to update because of the move.

=head2 direction

usually returns the direction of the player (C<left>, C<right>, C<up>, C<down>). You may want to use this if you create a graphical front-end.

=head2 solved

returns true if everything is placed correctly.

=head1 SEE ALSO

L<Games::Sokoban>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
