##########################################################################
package Games::PangZero::MenuItem;
##########################################################################

@ISA = qw(Games::PangZero::GameObject);
use strict;
use warnings;
use vars qw($Gravity);
$Gravity = 0.2;

sub new {
  my ($class, $x, $y, $text) = @_;
  my $self                   = Games::PangZero::GameObject->new();
  %{$self}                   = ( %{$self},
    'targetX'   => $x,
    'targetY'   => $y,
    'h'         => 42,
    'selected'  => 0,
    'filled'    => 0,
    'fillcolor' => SDL::Color->new(0, 0, 128),
    'parameter' => 0,
    'tooltip'   => [ @_[4 .. $#_] ],
  );
  bless $self, $class;
  $self->SetText($text);
  $self->SetInitialSpeed();
  return $self;
}

sub Center {
  my $self         = shift;
  $self->{targetX} = ( $Games::PangZero::ScreenWidth - $self->{w} ) / 2;
}

sub Show {
  my $self = shift;
  return if $self->CanSelect();
  $self->SetInitialSpeed();
}

sub Hide {
  my $self        = shift;
  $self->SUPER::Clear();
  $self->{state}  = 'leaving';
  $self->{speedX} = rand(10) - 5;
}

sub HideAndDelete {
  my $self                   = shift;
  $self->Hide();
  $self->{deleteAfterHiding} = 1;
}

sub Delete {
  my $self          = shift;
  $self->{selected} = $self->{filled} = 0;
  $self->SUPER::Delete();
}

sub ApproachingSpeed {
  my ($position, $speed, $target) = @_;

  if ($position + $speed * abs($speed / $Gravity) / 2 > $target) {
    return $speed - $Gravity;
  } else {
    return $speed + $Gravity;
  }
}

sub Advance {
  my $self = shift;

  if ('entering' eq $self->{state}) {
    $self->{x}     += $self->{speedX};
    $self->{y}     += $self->{speedY};
    $self->{speedX} = ApproachingSpeed($self->{x}, $self->{speedX}, $self->{targetX});
    $self->{speedY} = ApproachingSpeed($self->{y}, $self->{speedY}, $self->{targetY});
    if ( abs($self->{x} - $self->{targetX}) + abs($self->{y} - $self->{targetY}) < 2 ) {
      $self->{x}     = $self->{targetX};
      $self->{y}     = $self->{targetY};
      $self->{state} = 'shown';
    }
  } elsif ('leaving' eq $self->{state}) {
    $self->{x}      += $self->{speedX};
    $self->{y}      += $self->{speedY};
    $self->{speedY} += $Gravity;
    if ($self->{y} > $Games::PangZero::PhysicalScreenWidth) {
      $self->{state} = 'hidden';
      $self->Delete() if $self->{deleteAfterHiding}
    }
  }
}

sub Draw {
  my $self = shift;

  return if $self->{state} eq 'hidden';
  $self->TransferRect();
  if ($self->{selected} or $self->{filled}) {
    SDL::Video::fill_rect($Games::PangZero::App, $self->{rect}, $self->{fillcolor});
  }
  SDLx::SFont::print_text( $Games::PangZero::App,$self->{x} + 5 +$Games::PangZero::ScreenMargin, $self->{y} + $Games::PangZero::ScreenMargin, $self->{text});
}

sub SetInitialSpeed {
  my $self        = shift;
  $self->{x}      = $self->{targetX} + rand(500) - 250;
  $self->{y}      = $Games::PangZero::PhysicalScreenHeight;
  $self->{speedY} = -sqrt( 2 * $Gravity * ($self->{y} - $self->{targetY}) );
  $self->{speedX} = 0;
  $self->{state}  = 'entering';
}

sub InternalSetText {
  my ($self, $text) = @_;
  $self->SUPER::Clear();
  $self->{text}     = $text;
  $self->{w}        = Games::PangZero::Graphics::TextWidth($text) + 10;
}

sub SetText {
  my ($self, $text)  = @_;
  $self->{parameter} = '';
  $self->{basetext}  = $text;
  $self->InternalSetText($text);
}

sub SetParameter {
  my ($self, $parameter) = @_;
  $self->{parameter}     = $parameter;
  $self->InternalSetText($self->{basetext} . ' ' . $parameter);
}

sub Select {
  my ($self) = @_;

  foreach my $item (@Games::PangZero::GameObjects) {
    $item->{selected} = 0 if ref $item eq 'Games::PangZero::MenuItem';
  }
  $self->{selected} = 1;
  $Games::PangZero::Game->ShowTooltip( @{$self->{tooltip}} );
}

sub CanSelect {
  my ($self) = @_;

  return $self->{state} =~ /(?:entering|shown)/;
}

1;
