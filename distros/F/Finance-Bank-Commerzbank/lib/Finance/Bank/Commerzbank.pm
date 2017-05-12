package Finance::Bank::Commerzbank;
use strict;
use Carp;
our $VERSION = '0.29';

use WWW::Mechanize;
use WWW::Mechanize::FormFiller;
use URI::URL;
our $ua = WWW::Mechanize->new( autocheck => 1 );
our $formfiller = WWW::Mechanize::FormFiller->new();
use Time::localtime;

sub check_balance {
  my ($class, %opts) = @_;
  my %HashOfAccounts;
  croak "Must provide a Teilnehmernummer" 
    unless exists $opts{Teilnehmernummer};
  croak "Must provide a PIN" 
    unless exists $opts{PIN};
  my $self = bless { %opts }, $class;
  
  $ua->env_proxy();
  $ua->get('https://portal01.commerzbanking.de/P-Portal/XML/IFILPortal/pgf.html?Tab=1');
  $ua->form(1) if $ua->forms and scalar @{$ua->forms};
  $ua->form_number(4);
  {
    local $^W; $ua->current_form->value('PltLogin_8_txtTeilnehmernummer', $opts{Teilnehmernummer});
  }
  ;
  {
    local $^W; $ua->current_form->value('PltLogin_8_txtPIN', $opts{PIN});
  }
  ;
  $ua->click('PltLogin_8_btnLogin');
  my @links=$ua->find_all_links();
  my $n; 
  for ($n=0;$n<$#links;$n++) {
    my ($url,$title)=@{$links[$n]};
    if ($opts{"debug"} eq "1") {
      print "LINK------>".$n." - ".$title."\n";
    }
  }
  if (0) {
    $ua->follow_link(text=>"Kontoübersicht");
    my $Overview=$ua->content;
    my $Konto;
    while (index($Overview,"PltViewAccountOverview_8_STR_KontoNummer")>-1) {
      $Konto=substr ($Overview,index($Overview,"PltViewAccountOverview_8_STR_KontoNummer")+46,15);
      $Overview=substr ($Overview,index($Overview,"PltViewAccountOverview_8_STR_KontoNummer")+46);
      if ($opts{"debug"} eq "1") {
	print $Konto."\n";
      }
    }
  }
  $ua->follow_link(text => "Kontoumsätze");
  @links=$ua->find_all_links();
  for ($n=0;$n<$#links;$n++) {
    my ($url,$title)=@{$links[$n]};
    print "LINK------>".$n." - ".$title."\n";
  }
  
  if ($opts{"debug"} eq "1") {
    write_file($ua->content,"/tmp/Commerzbank-0");
  }
  if ( $ua->form_number(5)) {
    if ($opts{"debug"} eq "1") {
      write_file($ua->content,"/tmp/Commerzbank-1");
    }
    {
      local $^W; $ua->current_form->value('PltViewAccountTransactions_8_STR_CodeZeitrahmen', '90 Tage');
      local $^W; $ua->current_form->value('PltViewAccountTransactions_8_STR_KontoNr', $opts{Kontonummer});
    }
    ;
    my $response= $ua->click('PltViewAccountTransactions_8_btnAnzeigen');
    write_file($ua->content,"/tmp/Account");
    $ua->form_number(4);
    $ua->click('PltHomeTeaser_3_btnLogout');
  } else {
    print "Could not log on - wait timeout detected..\n";
  }
  
  
  
  use HTML::TableContentParser;
  my $p = HTML::TableContentParser->new();
  
  open(IN,"</tmp/Account");
  my $Data;
  my $go;
  while (<IN>) {
    if (index($_,"Buchungstag")>-1) {
      $go=1;
    }
    if ($go) {
      $Data.=$_;
    }
  }
  if ( ($opts{"debug"} ne "1") && ( -r "/tmp/Account" )) {
    # We remove the temporary file only in non-debug mode...
    `rm /tmp/Account`;
  }
  
  my $tables = $p->parse($Data);
  my $t;
  my $r;
  my @accounts;
  for $t (@$tables) {
    my $j=0;
    for $r (@{$t->{rows}}) {
      my $i=0;
      my $IsOk=0;
      my $c;
      my @line;
      for $c (@{$r->{cells}}) {
	#	print "CELL :$i\n";
	my $Data;
	if (($i == 1 ) || ($i == 5 )|| ($i == 7 ) ) {
	  
	  $Data=substr($c->{data},index($c->{data},"tablehead1")+12,1000);
	  $Data =~ s/<\/span><br>//g;
	  $Data =~s/<BR>/#/g;
	  my $year=localtime->year()+1900;
	  my $year_before=localtime->year()+1900-1;
	  if (($i ==1 ) &&  ( (index($Data,$year)>-1) || (index($Data,$year_before)>-1))) {
	    $IsOk=1;
	    $j++;
	    #	    print "Transaction - $j:";
	  }
	  if ($IsOk) {
	    push @line,$Data;
	    #	    print "Push IsOK".$Data.";";                          
	  }
	}
	if ($i == 10) {
	  #    print "[$c->{data}]";
	  if (index($c->{data},'"red">')> -1) {
	    $Data=substr($c->{data},index($c->{data},"red")+5,1000);
	  }
	  if (index($c->{data},'"green">')> -1) {
	    $Data=substr($c->{data},index($c->{data},"green")+7,1000);
	  }
	  $Data =~ s/<\/span><br>//g;
	  if ($IsOk) {
	    $Data =~ s/\.//g;
	    push @line,$Data;
	    push @accounts, (bless {
				    TradeDate           => $line[0],
				    Description         => $line[1],
				    ValueDate           => $line[2],
				    Amount              => $line[3],
				    parent     => $self
				   }, "Finance::Bank::Commerzbank::Account");
	  }
	}
	$i++;
      }
    }
  }
  return @accounts;
}

sub money_transfer {
  my ($class, %opts) = @_;
  #Checking all necessary InputParameters
  croak "Must provide : Teilnehmernummer" 
    unless exists $opts{Teilnehmernummer};
  croak "Must provide : PIN"
    unless exists $opts{PIN};
  croak "Must provide : TANPIN"
    unless exists $opts{TANPIN};
  croak "Must provide : EmpfaengerName"
    unless exists $opts{EmpfaengerName};
  croak "Must provide : EmpfaengerKtoNr"
    unless exists $opts{EmpfaengerKtoNr};
  croak "Must provide : EmpfaengerBLZ"
    unless exists $opts{EmpfaengerBLZ};
  croak "Must provide : Betrag_Eingabe"
    unless exists $opts{Betrag_Eingabe};

  my $self = bless { %opts }, $class;
  
  $ua->env_proxy();
  
  $ua->get('https://portal01.commerzbanking.de/P-Portal/XML/IFILPortal/pgf.html?Tab=1');
  $ua->form(1) if $ua->forms and scalar @{$ua->forms};
  $ua->form_number(4);
  {
    local $^W; $ua->current_form->value('PltLogin_8_txtTeilnehmernummer', $opts{Teilnehmernummer});
  }
  ;
  {
    local $^W; $ua->current_form->value('PltLogin_8_txtPIN', $opts{PIN});
  }
  ;
  $ua->click('PltLogin_8_btnLogin');
  my @links=$ua->find_all_links();
  my $n; 
  for ($n=0;$n<$#links;$n++) {
    my ($url,$title)=@{$links[$n]};
    print "LINK------>".$n." - ".$title."\n";
      
  }
  $ua->follow_link(text => "Inlandsüberweisung");
  @links=$ua->find_all_links();
  for ($n=0;$n<$#links;$n++) {
    my ($url,$title)=@{$links[$n]};
    print "LINK------>".$n." - ".$title."\n";
      
  }
  if ($opts{"debug"} eq "1") {
    write_file($ua->content,"/tmp/Commerzbank-0");
  }
  if ( $ua->form_number(5)) {
    if ($opts{"debug"} eq "1") {
      write_file($ua->content,"/tmp/Commerzbank-1");
    }
    {
      local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_EmpfaengerName', $opts{EmpfaengerName});
    }
    ;
    {
      local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_EmpfaengerKtoNr', $opts{EmpfaengerKtoNr});
    }
    ;
    {
      local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_EmpfaengerBLZ', $opts{EmpfaengerBLZ});
    }
    ;
    {
      local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_DBL_Betrag_Eingabe',$opts{Betrag_Eingabe});
    }
    ;
    {
      local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_Verwendungszweck1', $opts{Verwendungszweck1});
    }
    ;
    {
      local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_Verwendungszweck2', $opts{Verwendungszweck2});
    }
    ;
    {
      local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_Verwendungszweck3', $opts{Verwendungszweck3});
    }
    ;
    {
      local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_Verwendungszweck4', $opts{Verwendungszweck4});
    }
    ;
    {
      local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_CBO_Konten', $opts{Auftragskonto});
    }
    ;
    print "Empfaenger       :".$opts{EmpfaengerName}."\n";
    print "Empfaenger Kto   :".$opts{EmpfaengerKtoNr}."\n";
    print "Empfaenger BLZ   :".$opts{EmpfaengerBLZ}."\n";
    print "Empfaenger Betrag:".$opts{Betrag_Eingabe}."\n";
    print "VZ 1             :".$opts{Verwendungszweck1}."\n";
    print "VZ 2             :".$opts{Verwendungszweck2}."\n";
    print "VZ 3             :".$opts{Verwendungszweck3}."\n";
    print "VZ 4             :".$opts{Verwendungszweck4}."\n";
    my $response= $ua->click('PltManageDomesticTransfer_8_btnPruefenDomestic');
    #$ua->click('PltManageDomesticTransfer_8_btnPruefenDomestic');
    sleep(3);
    $ua->form_number(5);
    {
      local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_STR_FECAF5D9B9AF914896', $opts{TANPIN});
      #The Form has changed.... below the old input for the tan
      #local $^W; $ua->current_form->value('PltManageDomesticTransfer_8_txtTANPIN', $opts{TANPIN});
    }
    ;
    $ua->click('PltManageDomesticTransfer_8_btnFreigebenDomestic');
    $ua->form_number(4);


    if ($opts{"debug"} eq "1") {
      write_file($ua->content,"/tmp/Commerzbank-2");
    }
    $ua->form_number(4);
    $ua->click('PltHomeTeaser_3_btnLogout');
  } else {
    print "Could not log on - wait timeout detected..\n";
  }
  
  
}

sub write_file {
  my ($Data,$FileName)=@_;
  open( OUT , ">".$FileName);
  print OUT $Data;
  close(OUT);
}




package Finance::Bank::Commerzbank::Account;
# Basic OO smoke 
no strict;
sub AUTOLOAD { my $self=shift; $AUTOLOAD =~ s/.*:://; $self->{$AUTOLOAD} }

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Finance::Bank::Commerzbank - Check your bank accounts from Perl

=head1 SYNOPSIS

  use Finance::Bank::Commerzbank;
  for (Finance::Bank::Commerzbank->check_balance(
        Teilnehmernummer  => $Teilnehmernummer, Kontonummer= $KtoNummer,
        PIN=> $PIN )) {
	printf ("Transaction No: %d - TradeDate: %s - Description: %s  - ValueDate:%s - Amount: %s\n",
	            $i,
		    $_->TradeDate,
	            $_->Description,
	            $_->ValueDate,
	            $_->Amount);

  }

  Finance::Bank::Commerzbank->money_transfer(
   Teilnehmernummer=>$Teilnehmernummer,
   PIN=>$PIN,
   EmpfaengerName=>"Fancy GMBH",
   EmpfaengerKto=>"8998817",
   EmpfaengerBLZ=>"30050000",
   Betrag_Eingabe=>"41,56",
   Verwendungszweck1=>"123123",
   Verwendungszweck2=>"RE 123123",
   Verwendungszweck3=>"Remark1",
   Verwendungszweck4=>"Remark2",

   Auftragskonto=>"133432100 EUR",
   TANPIN=>"123456");


=head1 DESCRIPTION

This module provides a rudimentary interface to the Commerzbank online
banking system at C<https://portal01.commerzbanking.de/P-Portal/XML/IFILPortal/pgf.html?Tab=1/>. You will need
either C<Crypt::SSLeay> or C<IO::Socket::SSL> installed for HTTPS
support to work with LWP.

=head1 CLASS METHODS

    check_balance(Teilnehmernummer => $Teilnehmernummer,  Kontonummer=>"133432100 EUR",PIN => $PIN)

Return a list of the last 90 days account transactions. 


  use Finance::Bank::Commerzbank;
  Finance::Bank::Commerzbank->money_transfer(
   Teilnehmernummer=>$Teilnehmernummer,
   PIN=>$PIN,
   EmpfaengerName=>"Fancy GMBH",
   EmpfaengerKto=>"8998817",
   EmpfaengerBLZ=>"30050000",
   Betrag_Eingabe=>"41,56",
   Verwendungszweck1=>"123123",
   Verwendungszweck2=>"RE 123123",
   Auftragskonto=>"133432100 EUR",
   TANPIN=>"123456");
   }

Method to transfer money, you must supply all values, carefully submit
the correct Auftragskonto. At the current stage this value must be provided
from outside. In future versions we try to select the correct main accout.


=head1 TODOS

At the current stage we protocol the temporary output from the HTML
side into temporary files under the /tmp/ directory. This will be 
changed in future versions. You could explicit force this if you 
supply the debug flag to the method call. In future releases the possible Accounts should be autodetected via a new method. At the current stage
you must parse the HTML output to find the correct Auftragskonto pattern.

=head1 WARNING

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 AUTHOR

Tobias Herbert<tobi@cpan.org>

=cut
