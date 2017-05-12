#!/usr/local/bin/perl -w

# Example script using Games::Boggle::Board
# Play a game of cgi-Boggle

# I have replaced my dictionary file with the Shorter 
# Oxford, available at
# http://www.puzzlers.org/secure/wordlists/dictinfo.php

-e 'soed.txt' ? my $dict = 'soed.txt' : my $dict = '';

use strict;

use HTML::Template;
my $template;

use CGI qw(param header);

if ( param('board') && param('words')) {

  $template = HTML::Template->new(filename=>'boggle-words.template') 
    or die;

  my $brd = build_board_array(param('board'));
  $template->param( board => $brd ); 

  use Games::Boggle;
  my $board = Games::Boggle->new(param('board'));

  my %scores = ( 
    3 => 1, 
    4 => 1, 
    5 => 2, 
    6 => 3, 
    7 => 5, 
    8 => 11, 
    9 => 11,
   10 => 11, 
   11 => 11, 
   12 => 11, 
   13 => 11, 
   14 => 11,
   15 => 11, 
   16 => 11 
  ); 

  my (@good, @bad);
  my  $total_score = 0; 

  foreach my $word 
  ( keys %{{ map {$_ => 1} split /\s+/, param('words') }} ) {
    next if $word =~ /\W/; # watch for nasties
    
    if ( length($word)>2 
         && $board->has_word($word) 
         && grep( /^$word$/, `look $word $dict`)
    ) { 
        push (@good, {word=>$word}); 
        $total_score += $scores{length($word)};
    }
    else { push (@bad, {word => $word}) }
  } 

  $template->param( good => \@good );
  $template->param( bad => \@bad );
  $template->param( score => $total_score );

}

else {

  $template = HTML::Template->new(filename=>'boggle.template') 
    or die;

  use Games::Boggle::Board;
  my $b = Games::Boggle::Board->new;

  $template->param( board_string => $b->as_string );

  my $board = build_board_array($b->as_string);
  $template->param( board => $board );
}

print header, $template->output();

# ++ to merlyn on perlmonks for re-write of this function 

sub build_board_array {
  my @board = split //, shift;
  s/Q/Qu/ foreach @board;
  @board = map {
    +{ line => [map +{ letter => $_ }, splice @board, 0, 4 ]};
  } 1..4;
  return \@board;
}

