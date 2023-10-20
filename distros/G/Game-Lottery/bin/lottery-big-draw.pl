#!/usr/bin/env perl

use 5.038;
use Game::Lottery;
use Getopt::Long::Descriptive;
use English;

my $help = q/
  Pick, Check, or get a ticket value.

  # pick 5 Megamillions games output data to mypicks.ticket
  # if no file picks display to STDOUT only.
  lottery-big-draw.pl --pick 5 --game MegaMillions --file mypicks.ticket

  # check winners for file mypicks.ticket
  lottery-big-draw.pl --winners "01 02 03 04 05 [06]" --file mypicks.ticket
  lottery-big-draw.pl -w winners.ticket -f mypicks.ticket

  # estimate expected value of a PowerBall ticket given the cash jackpot
  # value of 1.6 bln (value can be given in millions or dollars)
  lottery-big-draw.pl -g PowerBall -t 1600

  /;

my ($opt, $usage) = describe_options(
  'lottery-big-draw.pl %o',
  [ 'pick|p=i', 'Pick Numbers requires the number of picks to make', ],
  [ 'file|f=s',   "file containing picks to check (or write to)",   ],
  [ 'winners|w=s', "String containing winning picks or location of file containing winners" ],
  [ 'ticketvalue|t=s', 'determine expected value of each ticket given cash value of jackpot'],
  [ 'game|g=s', "the game: PowerBall or MegaMillions", { required => 1 } ],
  [],
  [ 'help|h',       "print usage message and exit", { shortcircuit => 1 } ],
);

if ($opt->help) {
  print( $help, $usage->text );
  exit;
}

my $lottery = Game::Lottery->new( game => $opt->game );

if ( $opt->pick ) {
  my @picks = ();
  for ( my $i = 1; $i <= $opt->pick; $i++) {
    print sprintf('%-5s', $i);
    push @picks, $lottery->BigDraw();
  }
  if ( $opt->file ) {
    $lottery->SavePicks( $opt->file, \@picks);
  }
} elsif ( $opt->ticketvalue ) {
  my $jp = $opt->ticketvalue;
  my $tv = $lottery->TicketValue( $opt->ticketvalue );
  if ( $jp < 10**6 ) { $jp ="${jp} Million Dollars"}
  else { $jp = "${jp} Dollars"}
  say "A ${\ $opt->game } ticket with a Jackpot of ${jp} is worth: \$${tv}";
} elsif ( $opt->winners ) {
  my $winf = $opt->winners ;
  if ( $winf !~ /[A-Za-z]/) {
    open (my $tmpfile, '>', '/tmp/lottery.tmp' ||
      die "unable to save winners to temporary file $!\n");
    say $tmpfile $winf ;
    close $tmpfile;
    $winf = '/tmp/lottery.tmp';
  }
  my @results = $lottery->CheckPicks ( $winf, $opt->file );
  local $LIST_SEPARATOR = "\n";
  say "@results";
}

=pod

=head1 NAME

lottery-big-drawl.pl

=head1 VERSION

version 1.02

=head1 About

This script will display information about lottery games, pick numbers to play, and check numbers from a file.

=head1 Usage

Usage instructions can be obtained from help. Details on the Module Game::Lottery, including the file format for tickets, can be obtained via the perldoc command.

  lottery-big-draw.pl --help
  perldoc Game::Lottery

=cut
