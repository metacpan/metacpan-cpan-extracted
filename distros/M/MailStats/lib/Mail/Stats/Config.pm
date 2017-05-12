package Mail::Stats::Config;

use AppConfig qw(:argcount);
use strict;

sub new {
  my $class = shift;
  
  my $cfg = shift;
  my $this = {
	      raw_cfg => $cfg,
	      message => "%% count %% new messages in %% mbox %%\n",
	     };
  
  # Now we set up the sort routines 
  bless $this, $class;

  $this->_parse_config();
  
  $this->_parse_args();

  return $this;
}

sub _parse_args {
  my $this = shift;
  
  # First set sorts 
  
  my $sort = $this->{raw_cfg}->{s}; # default just in case

  if($sort eq 'A') {
    $this->{sort} = sub {$Mail::Stats::b cmp $Mail::Stats::a};
  } elsif($sort eq 'N') {
    $this->{sort} = sub {my $hash = shift; $hash->{$Mail::Stats::b}->num_unread() <=> $hash->{$Mail::Stats::a}->num_unread()};
  } elsif($sort eq 'n') {
    $this->{sort} = sub {my $hash = shift; $hash->{$Mail::Stats::a}->num_unread() <=> $hash->{$Mail::Stats::b}->num_unread()};
  } elsif($sort eq 'a') { # defaults to 'a'
    $this->{sort} = sub {$Mail::Stats::a cmp $Mail::Stats::b};
  }
  
  if($this->{raw_cfg}->{m}) {
    $this->{mboxen} = [split(/:/,$this->{raw_cfg}->{m})];
  }
  $this->{showall} = 1 if $this->{raw_cfg}->{a};
  
}

sub _parse_config {
  my $this = shift;
  
  my $config = AppConfig->new(
			      {
			       CASE => 0,
			       CREATE => 1,
			       ERROR => sub {return},
			       GLOBAL => {
					  ARGCOUNT => ARGCOUNT_ONE,
					 }
			      }
			     );
  $config->define("mailbox" => {ARGCOUNT => ARGCOUNT_LIST});
  
  my $cfgfile = $this->{raw_cfg}->{c} || "$ENV{HOME}/.countmailrc";
  $config->file($cfgfile);
  
  $this->{mboxen} = $config->mailbox;
  if($config->message()) {
    my $temp = $config->message();
    # do some quick fix ups so you can put tabs or newlines in 
    # the message format
    $temp =~ s/\\n/\n/;
    $temp =~ s/\\t/\t/;
    $this->{message} = $temp;
  }
  
  
}


1;


