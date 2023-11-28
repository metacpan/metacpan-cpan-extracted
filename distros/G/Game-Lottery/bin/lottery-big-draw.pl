#!/usr/bin/env perl

use 5.038;
use Game::Lottery;
use Getopt::Long::Descriptive;
use English;
use Pod::Usage;

my ( $opt, $usage ) = describe_options(
  'lottery-big-draw.pl %o',
  [ 'pick|p=i', 'Pick Numbers requires the number of picks to make', ],
  [ 'file|f=s', 'file containing picks to check (or write to)', ],
  [
    'winners|w=s',
    'String containing winning picks or location of file containing winners'
  ],
  [
    'ticketvalue|t=s',
    'determine expected value of each ticket given cash value of jackpot'
  ],
  [
    'game|g=s',
    "the game: Draw, Custom, PowerBall or MegaMillions",
    { required => 1 }
  ],
  [
    'custname|cn=s',
    'Optional Name for a custom game',
    { default => 'Custom Game' }
  ],
  [ 'whiteballs|wb=i', 'For Draw or Custom game, number of white balls' ],
  [
    'drawwhiteballs|drawhiteballs|dwb=i',
    'For Draw or Custom game, number of white balls to draw'
  ],
  [
    'redballs|rb=i', 'For Custom game, number of red balls', { default => 0 }
  ],
  [
    'drawredballs|drb=i',
    'For Custom game, number of red balls to draw',
    { default => 0 }
  ],
  [],
  [ 'help|h', "print usage message and exit", { shortcircuit => 1 } ],
);

if ( $opt->help ) {
  print pod2usage( -verbose => 2, -message => $usage->text );
  exit;
}

my $lottery = Game::Lottery->new( game => $opt->game );

sub custom_setup {
  if ( $opt->game =~ /custom/i ) {
    unless ( $opt->whiteballs && $opt->drawwhiteballs ) {
      die "for picking a custom game whiteballs and drawwhiteballs are required\n";
    }
    if ( $opt->redballs ) {
      my %balls = (
        white      => $opt->whiteballs,
        whitecount => $opt->drawwhiteballs,
        red        => $opt->redballs,
        redcount   => $opt->drawredballs,
        game       => $opt->custname,
      );
      $lottery->CustomBigDrawSetup(%balls);
    }
  }
}

if ( $opt->pick ) {
  custom_setup();
  my @picks = ();
  for ( my $i = 1 ; $i <= $opt->pick ; $i++ ) {
    printf( '%-5s', $i );
    my $draw = do {
      if ( $lottery->Game eq 'Draw' ) {
        {
          game => 'Draw', redballs => [],
          whiteballs =>
            $lottery->BasicDraw( $opt->whiteballs, $opt->drawwhiteballs )
        }
      } else {
        $lottery->BigDraw();
      }
    };
      #   $opt->drawredballs
      # ? $lottery->BigDraw()
      # : {
      # game       => $lottery->Game,
      # whiteballs =>
      #   $lottery->BasicDraw( $opt->whiteballs, $opt->drawwhiteballs ),
      # redballs => [],
      # };
    say
qq/${\ $draw->{game} } | ${\ do { join ' ', $draw->{whiteballs}->@* } } | ${\ do { join ' ', $draw->{redballs}->@* } }/;
    push @picks, $draw;
  }
  if ( $opt->file ) {
    $lottery->SavePicks( $opt->file, \@picks );
  }
}
elsif ( $opt->ticketvalue ) {
  my $jp = $opt->ticketvalue;
  my $tv = $lottery->TicketValue( $opt->ticketvalue );
  if   ( $jp < 10**6 ) { $jp = "${jp} Million Dollars" }
  else                 { $jp = "${jp} Dollars" }
  say
    "A ${\ $lottery->Game } ticket with a Jackpot of ${jp} is worth: \$${tv}";
}
elsif ( $opt->winners ) {
  my $winf = $opt->winners;
  if ( $winf !~ /[A-Za-z]/ ) {
    open(
      my $tmpfile,
      '>',
      '/tmp/lottery.tmp'
        || die "unable to save winners to temporary file $!\n"
    );
    say $tmpfile $winf;
    close $tmpfile;
    $winf = '/tmp/lottery.tmp';
  }
  my @results = $lottery->CheckPicks( $winf, $opt->file );
  local $LIST_SEPARATOR = "\n";
  say "@results";
}

=pod

=head1 NAME

lottery-big-drawl.pl

=head1 VERSION

version 1.04

=head1 About

This script will display information about lottery games, pick numbers to play, and check 
numbers from a file.

=head1 Usage

  # pick 5 Megamillions games output data to mypicks.ticket
  # if no file picks display to STDOUT only.
  lottery-big-draw.pl --pick 5 --game MegaMillions --file mypicks.ticket

  # check winners for file mypicks.ticket
  lottery-big-draw.pl --winners "01 02 03 04 05 [06]" --file mypicks.ticket
  lottery-big-draw.pl -w winners.ticket -f mypicks.ticket

  # estimate expected value of a PowerBall ticket given the cash jackpot
  # value of 1.6 bln (value can be given in millions or dollars)
  lottery-big-draw.pl -g PowerBall -t 1600

  # custom games can be created with the custom type and options.

  lottery-big-draw.pl -g Custom --wb 50 --dwb 5 --rb 30 --drb 1 -p 1 -f $filepath \
    --custname "My Custom Lottery"  

  # Basic draw games use only the whiteballs.

  lottery-big-draw.pl -g draw --wb 50 --dwb 5 -p 10

=head1 Additional Documentation

lottery-big-drawl.pl us bundled with Game::Lottery, additional information
can be obtained with the command C<perldoc Game::Lottery>. The file format 
is detailed there.

=head1 Command Line Options

  lottery-big-draw.pl [-fghptw] [long options...]

    --pick INT (or -p)         Pick Numbers requires the number of picks
                                to make
    --file STR (or -f)         file containing picks to check (or write to)
    --winners STR (or -w)      String containing winning picks or
                                location of file containing winners
    --ticketvalue STR (or -t)  determine expected value of each ticket
                                given cash value of jackpot
    --game STR (or -g)         the game: Draw, Custom, PowerBall or
                                MegaMillions
    --custname STR             Optional Name for a custom game
                                aka --cn
    --whiteballs INT           For Draw or Custom game, number of white balls
                                aka --wb
    --drawwhiteballs INT       For Draw or Custom game, number of white
                                balls to draw
                                aka --drawhiteballs, --dwb
    --redballs INT             For Custom game, number of red balls
                                aka --rb
    --drawredballs INT         For Custom game, number of red balls to draw
                                aka --drb

    --help (or -h)             print usage message and exit

=cut
