package Games::PangZero::Graphics;

use strict;
use warnings;

use SDL;
use SDL::Surface;
use SDL::Palette;
use SDL::PixelFormat;
use SDL::Video;
use SDL::Event;
use SDL::Events;
use SDL::Color;
use SDL::Config;
use SDL::Cursor;
use SDL::GFX::Rotozoom;
use SDL::Mixer;
use SDL::Mixer::Samples;
use SDL::Mixer::Channels;
use SDL::Mixer::Music;
use SDL::Mixer::MixChunk;
use SDL::Mixer::MixMusic;
use SDL::Joystick;
use SDL::Mouse;
use SDL::Image;
use SDLx::App;
use SDLx::SFont;

sub LoadSurfaces {
  my ($i, $transparentColor);

  my %balls = qw (
  ball0 Balls-Red128.png ball1 Balls-Red96.png ball2 Balls-Red64.png ball3 Balls-Red32.png ball4 Balls-Red16.png
  xmas Balls-XMAS128.png
  ball4 Balls-Red16.png ball3 Balls-Red32.png
  bouncy2 Balls-Bouncy64.png bouncy3 Balls-Bouncy32.png bouncy4 Balls-Bouncy16.png
  hexa0 Hexa-64.png hexa1 Hexa-32.png hexa2 Hexa-16.png
  blue1 Balls-Water96.png blue2 Balls-Water64.png blue3 Balls-Water32.png blue4 Balls-Water16.png
  frag0 Balls-Fragile128.png frag1 Balls-Fragile96.png frag2 Balls-Fragile64.png frag3 Balls-Fragile32.png frag4 Balls-Fragile16.png
  green1 Balls-SuperClock96.png green2 Balls-SuperClock64.png gold1 Balls-SuperStar96.png gold2 Balls-SuperStar64.png
  death2 Balls-Death64.png
  white2 Balls-Seeker64.png white3 Balls-Seeker32.png
  quake2 Balls-EarthQ64.png quake3 Balls-EarthQ32.png quake4 Balls-EarthQ16.png
  upside0 Balls-Upside128.png upside1 Balls-Upside96.png upside2 Balls-Upside64.png upside3 Balls-Upside32.png upside4 Balls-Upside16.png
  );

  foreach (sort keys %balls) {
    $Games::PangZero::BallSurfaces{$_} = SDL::Image::load("$Games::PangZero::DataDir/$balls{$_}");
    $Games::PangZero::BallSurfaces{$_} = SDL::Video::display_format($Games::PangZero::BallSurfaces{$_});
    $transparentColor = $Games::PangZero::BallSurfaces{$_}->get_pixel(0);
    SDL::Video::set_color_key($Games::PangZero::BallSurfaces{$_}, SDL_SRCCOLORKEY, $transparentColor );
    $Games::PangZero::BallSurfaces{"dark$_"} = SDL::Image::load( "$Games::PangZero::DataDir/$balls{$_}");
    $Games::PangZero::BallSurfaces{"dark$_"} = SDL::Video::display_format($Games::PangZero::BallSurfaces{"dark$_"});
    SDL::Video::set_color_key($Games::PangZero::BallSurfaces{"dark$_"}, SDL_SRCCOLORKEY, $Games::PangZero::BallSurfaces{"dark$_"}->get_pixel(0) );
    SDL::Video::set_alpha($Games::PangZero::BallSurfaces{"dark$_"}, SDL_SRCALPHA, 128);
  }

  $Games::PangZero::BorderSurface          = SDL::Image::load("$Games::PangZero::DataDir/border.png");
  $Games::PangZero::RedBorderSurface       = SDL::Image::load("$Games::PangZero::DataDir/border.png");
  $Games::PangZero::WhiteBorderSurface     = SDL::Image::load("$Games::PangZero::DataDir/border.png");
  $Games::PangZero::BonusSurface           = SDL::Image::load("$Games::PangZero::DataDir/bonus.png");
  $Games::PangZero::LevelIndicatorSurface  = SDL::Image::load("$Games::PangZero::DataDir/level.png");
  $Games::PangZero::LevelIndicatorSurface2 = SDL::Image::load("$Games::PangZero::DataDir/level_empty.png");

  AlterPalette( $Games::PangZero::RedBorderSurface, sub { 1; },
    sub { shift @_; my ($h, $s, $i) = Games::PangZero::Palette::RgbToHsi(@_);
    return Games::PangZero::Palette::HsiToRgb( $h - 30, $s, $i * 0.75 + 63); } );
  AlterPalette( $Games::PangZero::WhiteBorderSurface, sub { 1; },
    sub { shift @_; my ($h, $s, $i) = Games::PangZero::Palette::RgbToHsi(@_);
    return Games::PangZero::Palette::HsiToRgb( 0, 0, $i*0.25 + 191 ); } );

  MakeGuySurfaces();
}

sub MakeGuySurface {
  my ($player) = @_;
  my ($guySurfaceFile, $guySurface, $whiteGuySurface, $harpoonSurface);

  $guySurfaceFile       = $Games::PangZero::DataDir . '/' . $Games::PangZero::GuyImageFiles[ $player->{imagefileindex} % scalar(@Games::PangZero::GuyImageFiles) ];
  $guySurface           = SDL::Image::load($guySurfaceFile);
  $whiteGuySurface      = SDL::Image::load($guySurfaceFile);
  $harpoonSurface       = SDL::Image::load("$Games::PangZero::DataDir/harpoon.png");
  $player->{hue}        = $Games::PangZero::GuyColors[$player->{colorindex}]->[0];
  $player->{saturation} = $Games::PangZero::GuyColors[$player->{colorindex}]->[1];

  AlterPalette($whiteGuySurface, sub {1;}, sub { return (255, 255, 255); } );
  AlterPalette( $guySurface, sub { $_[3] > $_[2] and $_[3] > $_[1]; },
    sub {
      shift @_;
      my ($h, $s, $i) = Games::PangZero::Palette::RgbToHsi(@_);
      return Games::PangZero::Palette::HsiToRgb($player->{hue}, $player->{saturation}, $i); }
  );
  AlterPalette( $harpoonSurface, sub { 1; },
    sub {
      shift @_;
      my ($h, $s, $i) = Games::PangZero::Palette::RgbToHsi(@_);
      return Games::PangZero::Palette::HsiToRgb($player->{hue}, $player->{saturation} * $s / 256, $i); }
  );
  $player->{guySurface}      = $guySurface;
  $player->{whiteGuySurface} = $whiteGuySurface;
  $player->{harpoonSurface}  = $harpoonSurface;
}

sub MakeGuySurfaces {
  foreach my $player (@Games::PangZero::Players) {
    MakeGuySurface($player);
  }

  $Games::PangZero::WhiteHarpoonSurface = SDL::Image::load("$Games::PangZero::DataDir/harpoon.png");
  AlterPalette($Games::PangZero::WhiteHarpoonSurface, sub {1;}, sub { return (255, 255, 255); } );
}

sub AlterPalette {
  my ($surface, $filterSub, $alterSub) = @_;
  my ($r, $g, $b);
  my ($palette, $numColors, $n, $color);

  $palette   = $surface->format->palette();
  $numColors = ($surface->format->BytesPerPixel == 1) ? $palette->ncolors() : -1;
  for ($n = 0; $n < $numColors; $n++) {
    $color       = $palette->color_index($n);
    ($r, $g, $b) = ( $color->r, $color->g, $color->b );

    next unless $filterSub->($n, $r, $g, $b);
    ($r, $g, $b) = $alterSub->($n, $r, $g, $b);
    $r = $g = $b = 4 if ($r == 0 and $g == 0 and $b == 0);

    $color->r($r);
    $color->g($g);
    $color->b($b);
    SDL::Video::set_colors($surface, $n, $color);
  }
  $surface = SDL::Video::display_format($surface);
}

sub RenderBorder {
  my ($borderSurface, $targetSurface) = @_;
  my ($dstrect, $srcrect1, $srcrect2, $xpos, $ypos, $width, $height);

  $width  = $Games::PangZero::ScreenWidth  + 2 * $Games::PangZero::ScreenMargin;
  $height = $Games::PangZero::ScreenHeight + 2 * $Games::PangZero::ScreenMargin;

  # Draw the corners
  $dstrect  = SDL::Rect->new(0, 0, 16, 16);
  $srcrect1 = SDL::Rect->new(0, 0, 16, 16);
  SDL::Video::blit_surface($borderSurface, $srcrect1, $targetSurface, $dstrect);
  $dstrect->x($width - 16); $srcrect1->x(144);
  SDL::Video::blit_surface($borderSurface, $srcrect1, $targetSurface, $dstrect);
  $dstrect->y($height - 16); $srcrect1->y(144);
  SDL::Video::blit_surface($borderSurface, $srcrect1, $targetSurface, $dstrect);
  $dstrect->x(0); $srcrect1->x(0);
  SDL::Video::blit_surface($borderSurface, $srcrect1, $targetSurface, $dstrect);

  if(SDL::Config->has('SDL_gfx_rotozoom')) {
    # Top border
    my $zoom = SDL::Surface->new(SDL_SWSURFACE(), 128, 16, 32);
    $srcrect1->x(16); $srcrect1->y(0); $srcrect1->w(128); $srcrect1->h(16);
    SDL::Video::blit_surface($borderSurface, $srcrect1, $zoom, SDL::Rect->new(0, 0, $srcrect1->w, $srcrect1->h) );
    $zoom = SDL::GFX::Rotozoom::zoom_surface($zoom, $Games::PangZero::ScreenWidth / 128, 1, SDL::GFX::Rotozoom::SMOOTHING_OFF());
    $dstrect->x(16); $dstrect->y(0);
    SDL::Video::blit_surface($zoom, SDL::Rect->new(0, 0, $zoom->w, $zoom->h), $targetSurface, $dstrect );

    # Left border
    $zoom = SDL::Surface->new(SDL_SWSURFACE(), 16, 128, 32);
    $srcrect1->x(0); $srcrect1->y(16); $srcrect1->h(128); $srcrect1->w(16);
    SDL::Video::blit_surface($borderSurface, $srcrect1, $zoom, SDL::Rect->new(0, 0, $srcrect1->w, $srcrect1->h) );
    $zoom = SDL::GFX::Rotozoom::zoom_surface($zoom, 1, $Games::PangZero::ScreenHeight / 128, SDL::GFX::Rotozoom::SMOOTHING_OFF());
    $dstrect->x(0); $dstrect->y(16);
    SDL::Video::blit_surface($zoom, SDL::Rect->new(0, 0, $zoom->w, $zoom->h), $targetSurface, $dstrect );
  }

  # Draw top and bottom border

  $srcrect1->w(128); $srcrect1->x(16); $srcrect1->y(0);
  $srcrect2 = SDL::Rect->new( 16, 144, 128, 16 );
  for ($xpos = 16; $xpos < $width-16; ) {
    $dstrect->x($xpos);
    $dstrect->y(0);
    SDL::Video::blit_surface($borderSurface, $srcrect1, $targetSurface, $dstrect);
    $dstrect->y($height - 16);
    SDL::Video::blit_surface($borderSurface, $srcrect2, $targetSurface, $dstrect);
    $xpos += $srcrect1->w();
    $srcrect1->w(16); $srcrect1->x(128);
    $srcrect2->w(16); $srcrect2->x(128);
  }

  # Draw left and right border

  $srcrect1->h(128); $srcrect1->y(16); $srcrect1->x(0);
  $srcrect2->h(128); $srcrect2->y(16); $srcrect2->x(144);
  for ($ypos = 16; $ypos < $height-16; ) {
    $dstrect->x(0);
    $dstrect->y($ypos);
    SDL::Video::blit_surface($borderSurface, $srcrect1, $targetSurface, $dstrect);
    $dstrect->x($width - 16);
    SDL::Video::blit_surface($borderSurface, $srcrect2, $targetSurface, $dstrect);
    $ypos += $srcrect1->h();
    $srcrect1->h(16); $srcrect1->y(128);
    $srcrect2->h(16); $srcrect2->y(128);
  }

  if(SDL::Config->has('SDL_gfx_rotozoom')) {
    # Top border
    my $zoom = SDL::Surface->new(SDL::Video::SDL_SWSURFACE(), 128, 16, 32);
    $srcrect1->x(16); $srcrect1->y(0); $srcrect1->w(128); $srcrect1->h(16);
    SDL::Video::blit_surface($borderSurface, $srcrect1, $zoom, SDL::Rect->new(0, 0, $srcrect1->w, $srcrect1->h) );
    $zoom = SDL::GFX::Rotozoom::zoom_surface($zoom, $Games::PangZero::ScreenWidth / 128, 1, SDL::GFX::Rotozoom::SMOOTHING_OFF());
    $dstrect->x(16); $dstrect->y(0);
    SDL::Video::blit_surface($zoom, SDL::Rect->new(0, 0, $zoom->w, $zoom->h), $targetSurface, $dstrect );

    # Left border
    $zoom = SDL::Surface->new( SDL_SWSURFACE(), 16, 128, 32);
    $srcrect1->x(0); $srcrect1->y(16); $srcrect1->h(128); $srcrect1->w(16);
    SDL::Video::blit_surface($borderSurface, $srcrect1, $zoom, SDL::Rect->new(0, 0, $srcrect1->w, $srcrect1->h) );
    $zoom = SDL::GFX::Rotozoom::zoom_surface($zoom, 1, $Games::PangZero::ScreenHeight / 128, SDL::GFX::Rotozoom::SMOOTHING_OFF());
    $dstrect->x(0); $dstrect->y(16);
    SDL::Video::blit_surface($zoom, SDL::Rect->new(0, 0, $zoom->w, $zoom->h), $targetSurface, $dstrect );
  }
}

sub LoadBackground {
  my $filename = shift;

  SDL::Video::fill_rect($Games::PangZero::Background, SDL::Rect->new(0, 0, $Games::PangZero::PhysicalScreenWidth, $Games::PangZero::PhysicalScreenHeight), SDL::Color->new(0, 0, 0) );
  my $backgroundImage = SDL::Image::load("$Games::PangZero::DataDir/$filename");
  my $dstrect         = SDL::Rect->new($Games::PangZero::ScreenMargin, $Games::PangZero::ScreenMargin, 0, 0);
  my $srcrect         = SDL::Rect->new(0, 0, $Games::PangZero::ScreenWidth, $Games::PangZero::ScreenHeight);
  if ($Games::PangZero::ScreenWidth != $backgroundImage->w() or $Games::PangZero::ScreenHeight != $backgroundImage->h()) {
    if (SDL::Config->has('SDL_gfx_rotozoom')) {
      my $zoomX        = $Games::PangZero::ScreenWidth  / $backgroundImage->w(); # $zoomX = 1.0 if $zoomX < 1.0;
      my $zoomY        = $Games::PangZero::ScreenHeight / $backgroundImage->h(); # $zoomY = 1.0 if $zoomY < 1.0;
      $backgroundImage = SDL::GFX::Rotozoom::zoom_surface($backgroundImage, $zoomX, $zoomY, SDL::GFX::Rotozoom::SMOOTHING_OFF());
    }
  }
  SDL::Video::blit_surface($backgroundImage, $srcrect, $Games::PangZero::Background, $dstrect);

  RenderBorder($Games::PangZero::BorderSurface, $Games::PangZero::Background);
}

sub TextWidth {
  SDLx::SFont::SDL_TEXTWIDTH(@_); # perl-sdl-2.x
}

sub FindVideoMode {
  if ($Games::PangZero::FullScreen < 2) {
    return (800, 600);
  }

  # Find a suitable widescreen mode
  # One native resolution:   1680 x 1050 => 1.6  : 1
  # Which could translate to: 840 x 525  => 1.6  : 1
  # Some adapters have:       848 x 480  => 1.76 : 1
  #                           720 x 480  => 1.5  : 1
  #                           800 x 512  => 1.56 : 1
  # Conclusion: Any resolution where w in [800,900], h > 480 and r in [1.5, 1.8] is good

  my ($modes, $mode, @goodModes, $w, $h, $ratio);
  $modes = SDL::ListModes( 0, SDL_HWSURFACE ); #add back fullscreen
  foreach $mode (@{$modes}) {
    $w     = $mode->w;
    $h     = $mode->h;
    $ratio = $w / $h;
    warn sprintf( "%4d x %4d => %0.3f\n", $w, $h, $ratio );
    next if $w < 800 or $w > 900;
    next if $h < 480;
    next if $ratio < 1.5 or $ratio > 1.8;
    push @goodModes, ( { -w => $w, -h => $h, -score => abs($ratio - 1.6) * 1000 + abs($w - 800) } );
  }
  @goodModes = sort { $a->{-score} <=> $b->{-score} } @goodModes;
  return (800, 600) unless @goodModes;
  foreach $mode (@goodModes) {
    print sprintf( '%d x %d => %0.3f (score %d)', $mode->{-w}, $mode->{-h}, $mode->{-w} / $mode->{-h}, $mode->{-score} ), "\n";
  }
  return ($goodModes[0]->{-w}, $goodModes[0]->{-h});
}

1;
