##########################################################################
# GLOBAL CONFIGURATION
##########################################################################
package Games::PangZero::Globals;

use Games::PangZero::Config;

%Sounds = (
  'pop' => 'pop.voc',
  'shoot' => 'shoot.voc',
  'death' => 'meow.voc',
  'level' => 'level.voc',
  'bonuslife' => 'magic.voc',
  'pause' => 'pop3.voc',
  'quake' => 'quake.voc',
);

@Games::PangZero::DifficultyLevels = (
  { 'name' => 'Easy',     'spawnmultiplier' => 1.2, 'speed' => 0.8, 'harpoons' => 5, 'superball' => 0.8, 'bonusprobability' => 0.2, },
  { 'name' => 'Normal',   'spawnmultiplier' => 1.0, 'speed' => 1.0, 'harpoons' => 3, 'superball' => 1.0, 'bonusprobability' => 0.1, },
  { 'name' => 'Hard',     'spawnmultiplier' => 0.9, 'speed' => 1.2, 'harpoons' => 2, 'superball' => 1.1, 'bonusprobability' => 0.05, },
  { 'name' => 'Nightmare','spawnmultiplier' => 0.8, 'speed' => 1.4, 'harpoons' => 2, 'superball' => 1.5, 'bonusprobability' => 0.02, },
  { 'name' => 'Miki',     'spawnmultiplier' => 0.4, 'speed' => 1.0, 'harpoons' => 3, 'superball' => 1.0, 'bonusprobability' => 0.1, },
);
Games::PangZero::Config::SetDifficultyLevel(1);
@Games::PangZero::WeaponDurations = (
  { 'name' => 'Short (Default)', 'durationmultiplier' => 1, },
  { 'name' => 'Medium', 'durationmultiplier' => 3, },
  { 'name' => 'Long',   'durationmultiplier' => 6, },
  { 'name' => 'Very Long', 'durationmultiplier' => 12, },
  { 'name' => 'Forever', 'durationmultiplier' => 10000, },
);
Games::PangZero::Config::SetWeaponDuration(0);

$Games::PangZero::NumGuys = 1;
@Games::PangZero::Players = (
  { 'keys'  => [SDLK_LEFT, SDLK_RIGHT, SDLK_UP], }, # blue
  { 'keys'  => [SDLK_a, SDLK_d, SDLK_s], },         # red
  { 'keys'  => [SDLK_j, SDLK_l, SDLK_k], },         # green
  { 'keys'  => [SDLK_KP6, SDLK_KP4, SDLK_KP5], },   # pink
  { 'keys'  => [SDLK_KP6, SDLK_KP4, SDLK_KP5], },   # yellow
  { 'keys'  => [SDLK_KP6, SDLK_KP4, SDLK_KP5], },   # cyan
  { 'keys'  => [SDLK_KP6, SDLK_KP4, SDLK_KP5], },   # gray
  { 'keys'  => [SDLK_KP6, SDLK_KP4, SDLK_KP5], },   # snot
  { 'keys'  => [SDLK_KP6, SDLK_KP4, SDLK_KP5], },   # purple
);
@Games::PangZero::GuyImageFiles = ( 'guyChristmas.png', 'guy_danigm.png', 'guy_pix.png', 'guy_pux.png', 'guy_r2.png', 'guy_sonic.png' );
@Games::PangZero::GuyColors     = ( [170, 255, 'blue'],   [  0, 255, 'red'],  [ 85, 255, 'green'], [212, 255, 'pink'],
                                    [ 42, 255, 'yellow'], [128, 255, 'cyan'], [128,   0, 'gray'],  [113, 128, 'snot'], [212, 64, 'purple'] );
for (my $i=0; $i<=$#Games::PangZero::Players; ++$i) {
  $Games::PangZero::Players[$i]->{number} = $i;
  $Games::PangZero::Players[$i]->{colorindex} = $i;
  $Games::PangZero::Players[$i]->{imagefileindex} = $i % scalar(@Games::PangZero::GuyImageFiles);
}

my %n0 = ('popIndex' => 0, 'rect' => SDL::Rect->new(0, 0, 128, 106));
my %n1 = ('popIndex' => 1, 'rect' => SDL::Rect->new(0, 0,  96,  80));
my %n2 = ('popIndex' => 2, 'rect' => SDL::Rect->new(0, 0,  64,  53));
my %n3 = ('popIndex' => 3, 'rect' => SDL::Rect->new(0, 0,  32,  28));
my %n4 = ('popIndex' => 4, 'rect' => SDL::Rect->new(0, 0,  16,  15));

@Games::PangZero::BallDesc = (
# Normal balls (n0 .. n4)
  { 'name' => 'n0', 'class' => 'Ball', 'score' =>  2000, 'spawndelay' =>   1, 'speedY' => 6.5, %n0, 'surface' => 'ball0', 'nextgen' => 'n1', },
  { 'name' => 'n1', 'class' => 'Ball', 'score' =>  1000, 'spawndelay' => 0.5, 'speedY' => 5.7, %n1, 'surface' => 'ball1', 'nextgen' => 'n2', },
  { 'name' => 'n2', 'class' => 'Ball', 'score' =>   800, 'spawndelay' => 0.25, 'speedY' => 5,  %n2, 'surface' => 'ball2', 'nextgen' => 'n3', },
  { 'name' => 'n3', 'class' => 'Ball', 'score' =>   600, 'spawndelay' => 0.12, 'speedY' => 4,  %n3, 'surface' => 'ball3', 'nextgen' => 'n4', },
  { 'name' => 'n4', 'class' => 'Ball', 'score' =>   500, 'spawndelay' => 0.05, 'speedY' => 3,  %n4, 'surface' => 'ball4', },
# "Bouncy" balls (b0..b2)
  { 'name' => 'b0', 'class' => 'Ball', 'score' =>  1500, 'spawndelay' => 0.5, 'speedY' => 5.7, %n2, 'surface' => 'bouncy2', 'nextgen' => 'b1', },
  { 'name' => 'b1', 'class' => 'Ball', 'score' =>   750, 'spawndelay' => 0.2, 'speedY' => 5,   %n3, 'surface' => 'bouncy3', 'nextgen' => 'b2', },
  { 'name' => 'b2', 'class' => 'Ball', 'score' =>   500, 'spawndelay' => 0.1, 'speedY' => 4.2, %n4, 'surface' => 'bouncy4' },
# Hexas (h0..h2)
  { 'name' => 'h0', 'class' => 'Hexa', 'score' =>  1500, 'spawndelay' => 0.5, 'popIndex' => 5, 'hexa' => 1,
    'surface' => 'hexa0', 'rect' => SDL::Rect->new(0, 0, 64, 52), 'nextgen' => 'h1', },
  { 'name' => 'h1', 'class' => 'Hexa', 'score' =>  1000, 'spawndelay' => 0.2, 'popIndex' => 6, 'hexa' => 1,
    'surface' => 'hexa1', 'rect' => SDL::Rect->new(0, 0, 32, 28), 'nextgen' => 'h2', },
  { 'name' => 'h2', 'class' => 'Hexa', 'score' =>   500, 'spawndelay' => 0.1, 'popIndex' => 7, 'hexa' => 1,
    'surface' => 'hexa2', 'rect' => SDL::Rect->new(0, 0, 16, 14),
    'magicrect' => SDL::Rect->new(48, 0, 16, 14), },
# Water ball
  { 'name' => 'w1', 'class' => 'WaterBall', 'score' =>  1500, 'spawndelay' => 0.4, 'speedY' => 5.7, %n1, 'surface' => 'blue1', 'nextgen' => 'w2', },
  { 'name' => 'w2', 'class' => 'WaterBall', 'score' =>  1000, 'spawndelay' => 0.2, 'speedY' => 5,   %n2, 'surface' => 'blue2', 'nextgen' => 'w3', },
  { 'name' => 'w3', 'class' => 'WaterBall', 'score' =>   800, 'spawndelay' => 0.1, 'speedY' => 4,   %n3, 'surface' => 'blue3', 'nextgen' => 'w4', },
  { 'name' => 'w4', 'class' => 'WaterBall', 'score' =>   600, 'spawndelay' => 0.05, 'speedY' => 3,  %n4, 'surface' => 'blue4', },
# Fragile
  { 'name' => 'f0', 'class' => 'FragileBall', 'score' =>  1500, 'spawndelay' => 0.8, 'speedY' => 6.5, %n0, 'surface' => 'frag0', 'nextgen' => 'f1', },
  { 'name' => 'f1', 'class' => 'FragileBall', 'score' =>  1500, 'spawndelay' => 0.4, 'speedY' => 5.7, %n1, 'surface' => 'frag1', 'nextgen' => 'f2', },
  { 'name' => 'f2', 'class' => 'FragileBall', 'score' =>  1000, 'spawndelay' => 0.2, 'speedY' => 5,   %n2, 'surface' => 'frag2', 'nextgen' => 'f3', },
  { 'name' => 'f3', 'class' => 'FragileBall', 'score' =>   800, 'spawndelay' => 0.1, 'speedY' => 4,   %n3, 'surface' => 'frag3', 'nextgen' => 'f4', },
  { 'name' => 'f4', 'class' => 'FragileBall', 'score' =>   600, 'spawndelay' => 0.05, 'speedY' => 3,  %n4, 'surface' => 'frag4', },
# Superball
  { 'name' => 'super0', 'class' => 'SuperBall', 'score' =>  1000, 'spawndelay' => 0.5, 'speedY' => 5.7, %n1, 'surface' => 'green1', },
  { 'name' => 'super1', 'class' => 'SuperBall', 'score' =>   800, 'spawndelay' => 0.25, 'speedY' => 5,  %n2, 'surface' => 'green2', },
  { 'name' => 'xmas', 'class' => 'XmasBall', 'score' =>  1000, 'spawndelay' => 0.5, 'speedY' => 6.5, %n0, 'surface' => 'xmas', },
# Death
  { 'name' => 'death', 'class' => 'DeathBall', 'score' => 0, 'spawndelay' => 0.5, 'speedY' => 5, %n2, 'surface' => 'death2', 'nextgen' => 'death', },
# Seeker
  { 'name' => 'seeker', 'class' => 'SeekerBall', 'score' => 1200, 'spawndelay' => 0.2, 'speedY' => 5.7, %n2, 'surface' => 'white2', 'nextgen' => 'seeker1', },
  { 'name' => 'seeker1', 'class' => 'SeekerBall', 'score' => 1200, 'spawndelay' => 0.1, 'speedY' => 5,  %n3, 'surface' => 'white3', },
# Quake
  { 'name' => 'quake',  'class' => 'EarthquakeBall', 'score' => 1600, 'spawndelay' => 0.7, 'speedY' => 5.7, %n2, 'surface' => 'quake2',
    'quake' => 5, 'nextgen' => 'quake1', },
  { 'name' => 'quake1', 'class' => 'EarthquakeBall', 'score' => 1200, 'spawndelay' => 0.2, 'speedY' => 5,   %n3, 'surface' => 'quake3',
    'quake' => 3, 'nextgen' => 'quake2', },
  { 'name' => 'quake2', 'class' => 'EarthquakeBall', 'score' => 1000, 'spawndelay' => 0.1, 'speedY' => 4.2, %n4, 'surface' => 'quake4',
    'quake' => 2, },
# Upside down ball
  { 'name' => 'u0', 'class' => 'UpsideDownBall', 'score' =>  2000, 'spawndelay' =>   1, 'speedY' => 5.8, %n0, 'surface' => 'upside0', 'nextgen' => 'u1', },
  { 'name' => 'u1', 'class' => 'UpsideDownBall', 'score' =>  1000, 'spawndelay' => 0.5, 'speedY' => 5.8, %n1, 'surface' => 'upside1', 'nextgen' => 'u2', },
  { 'name' => 'u2', 'class' => 'UpsideDownBall', 'score' =>   800, 'spawndelay' => 0.25, 'speedY' =>5.8, %n2, 'surface' => 'upside2', 'nextgen' => 'u3', },
  { 'name' => 'u3', 'class' => 'UpsideDownBall', 'score' =>   600, 'spawndelay' => 0.12, 'speedY' =>5.9, %n3, 'surface' => 'upside3', 'nextgen' => 'u4', },
  { 'name' => 'u4', 'class' => 'UpsideDownBall', 'score' =>   500, 'spawndelay' => 0.05, 'speedY' =>5.9, %n4, 'surface' => 'upside4', },

  { 'name' => 'credits1', 'class' => 'Ball', 'speedY' => 6.1, 'nextgen' => 'credits1', 'surface' => 'blue3', %n3 },
  { 'name' => 'credits2', 'class' => 'Ball', 'speedY' => 6.1, 'nextgen' => 'credits2', 'surface' => 'ball3',  %n3 },
);
{
  foreach my $ballDesc (@Games::PangZero::BallDesc) {
    $ballDesc->{width}                            = $ballDesc->{rect}->w();
    $ballDesc->{height}                           = $ballDesc->{rect}->h();
    $Games::PangZero::BallDesc{$ballDesc->{name}} = $ballDesc;
  }
  foreach my $ballDesc (@Games::PangZero::BallDesc) {
    my $nextgen = $ballDesc->{nextgen};
    $ballDesc->{nextgen} = $Games::PangZero::BallDesc{$nextgen} if $nextgen;
  }
}

@Games::PangZero::ChallengeLevels = (
  'n4 n4 n4 n4 xmas',
  'n3 n3 n3',
  'n2 n2',
  'b0 b0',
  'h2 h2 h2 h2 h2 h2',
  'h0 h0',
  'n1 f2',
  'w1 n2',
  'n0 b0 w1 h0',
# 10
  'n1 quake',
  'n1 b0 quake',
  'w1 seeker u2',
  'n0 seeker seeker',
  'w1 w1',
  'f1 quake h0',
  'w1 seeker h0 h0',
  'n0 w1 w1 b0 h0',
  'u0 u0 quake',
  'quake quake w1 b0 h0',
# 20
  'death n1 b0',
  'n4 ' x 24,
  'w1 w1 w1 f0',
  'death w1 h0',
  'n0 n0 u0 seeker h2 h2 b0',
  'n4 b2 h2 u4 ' x 6,
  'quake quake quake b0',
  'h0 h0 h0 h0 h0 h0 h0 h0',
  'quake seeker f3 n1 b0 b0',
  'death death w1 f0 n0 u2 h0',
# 30
  'n0 n0 u0 u0',
  'death quake n1',
  'b0 h0 n2 ' x 3,
  'w1 w1 w1 w1 f1 f1',
  'n3 n3 n3 u3 ' x 4,
  'quake quake seeker seeker n0 f0',
  'seeker ' x 8,
  'n0 n1 n2 n3 n4 b0 f2 h0 h1 h2 w1 seeker',
  'quake quake quake h0 h0 h0 u2',
  'death quake seeker w1 n0 b0 h0',
# 40
  'n0 n1 n2 ' x 3,
  'death quake seeker u2 ' x 3,
  'f0 f0',
  'death quake f0 n1 ' x 2,
  'h0 ' x 8 . ' f0 f1 ',
  'death ' x 10,
  'quake b0 ' x 5,
  'w1 w1 f0 f1 death',
  'seeker ' x 13,
  'n0 u0 w1 f0 quake death ' x 2,
);

for ( my $i = 0; $i < 10; ++$i) {
  $Games::PangZero::ChallengeLevels[$i + 49] = $Games::PangZero::ChallengeLevels[$i +  9] . ' ' . $Games::PangZero::ChallengeLevels[$i + 29];
  $Games::PangZero::ChallengeLevels[$i + 59] = $Games::PangZero::ChallengeLevels[$i + 19] . ' ' . $Games::PangZero::ChallengeLevels[$i + 39];
}
foreach (@Games::PangZero::ChallengeLevels) {
  while (/(\w+)/g) {
    die "Unknown ball '$1' in challenge '$_'" unless defined $Games::PangZero::BallDesc{$1};
  }
}

my %BallMixes = (
  'easy'   => [ qw(n0  2 n1 20 n2 10 n3 3 n4 2  f0 3  f1 5  f2 5  b0 5 b1 2 b2 1   w1 10  h0 5  h1 3 h2 1     quake 1   seeker  2  u1 1 u2 2 u3 4 u4 1) ],
  'medium' => [ qw(n0 10 n1 20 n2 10 n3 3 n4 2  f0 3  f1 3  b0 10 b1 2 b2 1  w1 15  h0 15 h1 5 h2 1  death 2  quake 5   seeker 10  u0 2 u1 5 u2 5 u3 5) ],
  'bouncy' => [ qw(n0 20 n1 10 n2 5 n3 1 n4 1   f0 3  f1 3  b0 30 b1 9 b2 1  w1 10  h0 15 h1 5       death 5  quake 10  seeker 15  u0 5 u1 5 u2 1 u3 1) ],
  'hard'   => [ qw(n0 20 n1 10 n2 5 n3 1        f0 5  f1 1  b0 20 b1 2       w1 20  h0 20 h1 5       death 10 quake 15  seeker 20  u0 5 u1 5 u2 1 u3 1) ],
  'watery' => [ qw(n0 20 n1 10 n2 5 n3 1 n4 1   f0 3  f1 1  b0 10 b1 5       w1 50  h0 15 h1 5       death 5  quake 10  seeker 15  u0 1 u1 5 u2 5 u3 1) ],
  'hexas'  => [ qw(n0 20 n1 10 n2 5 n3 1        f0 3  f1 1  b0 15 b1 2       w1 20  h0 40 h1 15      death 5  quake 10  seeker 15  u0 1 u1 8 u2 2 u3 1) ],
  'quakes' => [ qw(n0 15 n1 10 n2 5 n3 1        f0 3  f1 1  b0 15            w1 15  h0 20 h1 5       death 5  quake 40  seeker 15  u0 8 u1 1 u2 2 u3 1) ],
);

sub AddLevels {
  my ($num, $balls, $gamespeedStart, $gamespeedEnd, $spawndelayStart, $spawndelayEnd) = @_;
  my ($i, $level);

  for ($i = 0; $i < $num; ++$i) {
    $level = {
      'balls'      => $balls,
      'gamespeed'  => $gamespeedStart  + ($gamespeedEnd  - $gamespeedStart)  * ($i) / ($num),
      'spawndelay' => $spawndelayStart + ($spawndelayEnd - $spawndelayStart) * ($i) / ($num),
    };
    push @Games::PangZero::PanicLevels, ( $level );
  }
}

AddLevels(  9, $BallMixes{easy},   0.75, 1.25, 20, 20 ); # 0-9
AddLevels( 10, $BallMixes{medium}, 0.7 , 1.3 , 20, 15 ); # 1x
AddLevels( 10, $BallMixes{hard},   0.7 , 1.5 , 15, 15 ); # 2x
AddLevels( 10, $BallMixes{hexas},  1.0 , 1.5 , 15, 12 ); # 3x
AddLevels( 10, $BallMixes{watery}, 0.7 , 1.7 , 15, 17 ); # 4x
AddLevels( 10, $BallMixes{bouncy}, 1.0 , 2.0 , 12, 12 ); # 5x
AddLevels( 10, $BallMixes{quakes}, 1.5 , 2.2 , 13,  8 ); # 6x
AddLevels( 10, $BallMixes{hard},   1.0 , 2.2 , 13, 10 ); # 7x
AddLevels( 10, $BallMixes{hexas},  1.3 , 2.4 , 12,  9 ); # 8x
AddLevels( 10, $BallMixes{hard},   2.0 , 3.0 , 13, 10 ); # 9x

# Set defaults

$Games::PangZero::ScreenMargin           = 16;
$Games::PangZero::ScreenWidth            = 800 - $Games::PangZero::ScreenMargin * 2;
$Games::PangZero::ScreenHeight           = 416;
$Games::PangZero::SoundEnabled           = 1;
$Games::PangZero::MusicEnabled           = 1;
$Games::PangZero::DeathBallsEnabled      = 1;
$Games::PangZero::EarthquakeBallsEnabled = 1;
$Games::PangZero::WaterBallsEnabled      = 1;
$Games::PangZero::SeekerBallsEnabled     = 1;
$Games::PangZero::FullScreen             = 1;
$Games::PangZero::UnicodeMode            = 0;
$Games::PangZero::Slippery               = 0;
$Games::PangZero::ShowWebsite            = 0;

1;
