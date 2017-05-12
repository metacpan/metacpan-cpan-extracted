package Window;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.01';

# {{{ new
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %args = @_;
  my $self = {
    grid => {
      content => $args{grid},
      extent => [ scalar @{$args{grid}[0]}, scalar @{$args{grid}} ] },
    viewport => $args{viewport},
    cursor => $args{cursor} || undef,
    corner => $args{corner} || [ 0, 0 ] };
  bless $self,$class }
# }}}

sub cursor { return @{shift->{cursor}} }
sub corner { return @{shift->{corner}} }

# {{{ square
sub square {
  my ($self,$x,$y) = @_;
  return $self->{grid}{content}[$self->{corner}[1]+$y]
                               [$self->{corner}[0]+$x] }
# }}}
# {{{ empty_square
sub empty_square {
  my ($self) = @_;
  return !defined
    $self->{grid}{content}[$self->{corner}[1]+$self->{cursor}[1]]
                          [$self->{corner}[0]+$self->{cursor}[0]] }
# }}}
# {{{ cur_square
sub cur_square {
  my ($self) = @_;
  return $self->{grid}{content}[$self->{corner}[1]+$self->{cursor}[1]]
                               [$self->{corner}[0]+$self->{cursor}[0]] }
# }}}
# {{{ set_square
sub set_square {
  my ($self,$x,$y,$content) = @_;
  $self->{grid}{content}[$self->{corner}[1]+$y]
                        [$self->{corner}[0]+$x] = $content }
# }}}
# {{{ set_cur_square
sub set_cur_square {
  my ($self,$content) = @_;
  $self->{grid}{content}[$self->{corner}[1]+$self->{cursor}[1]]
                        [$self->{corner}[0]+$self->{cursor}[0]] = $content }
# }}}
# {{{ take_cur_square
sub take_cur_square {
  my ($self) = @_;
  my $piece =
    $self->{grid}{content}[$self->{corner}[1]+$self->{cursor}[1]]
                          [$self->{corner}[0]+$self->{cursor}[0]];
    $self->{grid}{content}[$self->{corner}[1]+$self->{cursor}[1]]
                          [$self->{corner}[0]+$self->{cursor}[0]] = undef;
  return $piece }
# }}}
# {{{ view
sub view {
  my $self = shift;
  my $view = [];
  for my $y (0..$self->{viewport}[1]-1) {
    my $temp = [ map { $self->square($_,$y) } (0..$self->{viewport}[0]-1) ];
    push @$view,$temp }
  return $view }
# }}}

# {{{ left
sub left {
  my $self = shift;
  $self->{corner}[0] = 0 if $self->{corner}[0] < 0;
  return if $self->{corner}[0] == 0;
  $self->{corner}[0]--;
  return 1 }
# }}}
# {{{ curs_left
sub curs_left {
  my $self = shift;
  return $self->left() if $self->{cursor}[0] == 0;
  $self->{cursor}[0]--;
  return 1 }
# }}}
# {{{ at_left
sub at_left { return shift()->{corner}[0] == 0 }
# }}}
# {{{ right
sub right {
  my $self = shift;
  return if $self->{corner}[0] == $self->{grid}{extent}[0] - $self->{viewport}[0];
  $self->{corner}[0]++;
  return 1 }
# }}}
# {{{ curs_right
sub curs_right {
  my $self = shift;
  return $self->right() if $self->{cursor}[0] == $self->{viewport}[0] - 1;
  $self->{cursor}[0]++;
  return 1 }
# }}}
# {{{ at_right
sub at_right {
  my $self = shift;
  return $self->{corner}[0] == $self->{grid}{extent}[0] - $self->{viewport}[0] }
# }}}
# {{{ up
sub up {
  my $self = shift;
  return if $self->{corner}[1] == 0;
  $self->{corner}[1]--;
  return 1 }
# }}}
# {{{ curs_up
sub curs_up {
  my $self = shift;
  return $self->up() if $self->{cursor}[1] == 0;
  $self->{cursor}[1]--;
  return 1 }
# }}}
# {{{ at_top
sub at_top { shift->{corner}[1] == 0 }
# }}}
# {{{ down
sub down {
  my $self = shift;
  return if $self->{corner}[1] == $self->{grid}{extent}[1] - $self->{viewport}[1];
  $self->{corner}[1]++;
  return 1 }
# }}}
# {{{ curs_down
sub curs_down {
  my $self = shift;
  return $self->down() if $self->{cursor}[1] == $self->{viewport}[1] - 1;
  $self->{cursor}[1]++;
  return 1 }
# }}}
# {{{ at_bottom
sub at_bottom {
  my $self = shift;
  return $self->{corner}[1] == $self->{grid}{extent}[1] - $self->{viewport}[1] }
# }}}

1;
__END__

=head1 NAME

Window - Create a virtual window into a MxN grid of data.

=head1 SYNOPSIS

  use Window;
  my $vp = Window->new(
   viewport => [3,3], # Define a 3x3 window onto a chessboard
   grid     => [ [qw(R N B K Q B N R)], # Pieces represented as text
                 [qw(P P P P P P P P)],
                 [(undef) x 8], # And blank squares as undef
                 [(undef) x 8], 
                 [(undef) x 8],
                 [(undef) x 8],
                 [qw(p p p p p p p p)],
                 [qw(r n b q k b n r)] ] );
  print $vp->square(0,0); # 'R' is the TR square in the viewport
  $vp->down;
  $vp->right;
  print $vp->square(0,0); # 'P' is now the TR square after moving down and right
  $vp->set_square(0,0,' ');$vp->set_square(0,1,'P'); # Move the pawn

=head1 DESCRIPTION

Given a two-D array of data, this module creates a smaller window onto the dataset that can be moved around with C<left()>, C<down()> &c methods. Use the C<square($x,$y)> method to get the data in a square relative to the upper-left corner of the window, and C<view()> to get the entire window's worth of data.

In addition, you can place a virtual cursor within the window, and use the C<curs_left()>, C<curs_down()> &c methods to move that cursor within the window. When the cursor reaches a boundary, the window moves, not the cursor.

The C<left()>, C<right()>, C<up()> and C<down()> routines return whether the window was moved or not. The only time the window can't be moved is when it's against a border.

C<curs_right()> &c likewise signal if the window couldn't be moved. The data grid doesn't wrap around, as it doesn't really make sense to wrap around a chessboard.

=head1 SEE ALSO

L<perl(1)>

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
