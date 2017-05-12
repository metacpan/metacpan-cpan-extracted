##########################################################################
package Games::PangZero::Pop;
##########################################################################

@ISA = qw(Games::PangZero::GameObject);

@Description = (
  { 'xoffset' => 0, 'yoffset' =>  0, 'srcx' => 128, 'srcy' => 0, 'sizex' => 128, 'sizey' => 106, },
  { 'xoffset' => 0, 'yoffset' =>  0, 'srcx' =>  96, 'srcy' => 0, 'sizex' =>  96, 'sizey' =>  80, },
  { 'xoffset' => 0, 'yoffset' =>  0, 'srcx' =>  64, 'srcy' => 0, 'sizex' =>  64, 'sizey' =>  53, },
  { 'xoffset' => 0, 'yoffset' =>  0, 'srcx' =>  32, 'srcy' => 0, 'sizex' =>  32, 'sizey' =>  28, },
  { 'xoffset' => 0, 'yoffset' =>  0, 'srcx' =>  16, 'srcy' => 0, 'sizex' =>  16, 'sizey' =>  15, },

  { 'xoffset' => 0, 'yoffset' =>  0, 'srcx' => 192, 'srcy' => 0, 'sizex' =>  64, 'sizey' =>  52, },
  { 'xoffset' => 0, 'yoffset' =>  0, 'srcx' =>  96, 'srcy' => 0, 'sizex' =>  32, 'sizey' =>  28, },
  { 'xoffset' => 0, 'yoffset' =>  0, 'srcx' =>  48, 'srcy' => 0, 'sizex' =>  16, 'sizey' =>  14, },
);

sub new {
  my ($class, $x, $y, $index, $surface) = @_;
  my $desc                              = $Games::PangZero::Pop::Description[$index],
  my $self                              = Games::PangZero::GameObject->new();
  %{$self}                              = ( %{$self},
    'x'       => $x + $desc->{xoffset},
    'y'       => $y + $desc->{yoffset},
    'w'       => $desc->{sizex},
    'h'       => $desc->{sizey},
    'desc'    => $desc,
    'anim'    => 0,
    'surface' => $surface,
  );
  bless $self, $class;
}

sub Advance {
  my $self = shift;

  if (++$self->{anim} >= 20) {
    $self->Delete();
  }
}

sub Draw {
  my $self    = shift;
  $self->TransferRect();
  my $phase   = int($self->{anim} / 5);
  $phase      = 3 if $phase > 3;
  my $srcrect = SDL::Rect->new(
    $self->{desc}->{srcx} + $phase * $self->{w},
    $self->{desc}->{srcy},
    $self->{w},
    $self->{h} );
  SDL::Video::blit_surface($self->{surface}, $srcrect, $Games::PangZero::App, $self->{rect} );
}

1;
