package Mail::Stats::Parser;

use strict;
use Mail::Stats::Record;

use vars qw($Start_Header $Status_Header $Ignore_Header $End_Header);

$Start_Header = 'From \S+\s+\w\w\w \w\w\w\s+\d+ \d+:\d+:\d+ \d+';
$Status_Header = '(X-)?Status:';
$Ignore_Header = 'Subject: DON\'T DELETE THIS MESSAGE -- FOLDER INTERNAL DATA';
$End_Header = '\s*';

sub parse {
  my $fh = shift;

  my $mail = new Mail::Stats::Record();
  
  my $header = 0;

  while(<$fh>) {
    if(/^From \S+\s+\w+ \w+\s+\d+ \d+:\d+:\d+ \d+/) {
      $header = 1;
      $mail->{MESSAGES}++;
    } elsif ($header && /^$Status_Header/og) {
      while(/(\w)/g) {
	$mail->{STATUS}->{$1}++;
      }
    } elsif ($header && /^$Ignore_Header/o) {
      $mail->{MESSAGES}--;
      $header = 0;
    } elsif ($header && /^$End_Header$/o) {
      $header = 0;
    }
  }

  return $mail;
}

1;
