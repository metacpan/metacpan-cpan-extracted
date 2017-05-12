use Lemonldap::Portal::Script;
use Data::Dumper;
my $file = shift;


open FILE, "< $file";
my $cp         = 1;
my $flag_deb   = 0;
my $flag_quest = 0;
my $flag_resp  = 0;
my $exchange;
my $question;
my $response;
my @des_exchanges;
my @required;
my $html;
while (<FILE>) {
    chop;
    chop;
    my $line = $_;
    if ( $line =~ /------+/ ) {
        $cp++;
        $flag_resp = 0;
        $flag_deb  = 0;
        $exchange->set_tirade('response',$response);
         $exchange->add_string("----------------------------------------Fin exchange $exchange->{numero}");
       push @des_exchanges, $exchange; 
       
       next;
    }
    if ( ( $flag_quest == 1 ) && ( $line =~ /^HTTP/ ) ) {
        $exchange->set_tirade('question',$question);
        $exchange->add_string('    ');
        $flag_quest = 0;
        $flag_resp  = 1;
    }

    if ( $flag_deb == 0 ) {
    #    print "je commence un exchange: $cp \n";
        $exchange = Lemonldap::Portal::Script::Exchange->new( numero => $cp, requete => $line );
        $flag_deb = 1;
        undef $question;
        undef $response;
       next;
    }

    if ( !$line ) {
        if ( ( $flag_deb == 1 ) && ( $flag_quest == 0 ) ) {
      $exchange->add_string('    ');
         
          $flag_quest = 1;
            next;
        }
        if ( ( $flag_deb == 1 ) && ( $flag_quest == 1 ) ) {
            $flag_quest = 0;
       $exchange->add_string('    ');
        
           $flag_resp  = 1;
            next;
        }

    }
    if ( $flag_quest == 1 ) {
        if ( !$question ) {
            $question = Lemonldap::Portal::Script::Question->new();
            $exchange->set_method($line);
        }
        else {
            $question->add_header($line);

        }
    #    print "on est dans question ech $cp\n";
    }
    if ( $flag_resp == 1 ) {
        if ( !$response ) {
            $exchange->set_tirade('question',$question);
            $exchange->set_ResponseCode($line);
            $response = Lemonldap::Portal::Script::Response->new();
        }
        else {
            $response->add_header($line);

        }

    #    print "on est dans reponse ech $cp\n";
    }
$exchange->add_string($line); 
}

close FILE;
### marquage des exchanges ###
for (@des_exchanges ) {
my $exchange= $_;
if ($exchange->{response}->{headers}->[0] =~ /gif|css|jpeg|jpg|javascript/i ) {
   $exchange->set_status('n'); }
       elsif ($exchange->{responsecode} =~ /^4/) {  
    $exchange->set_status('n') ;}
             else 

          { $exchange->set_status('y'); 
}

}
my $cpe;
for (@des_exchanges ) {
my $exchange= $_;

if ($exchange->{require} eq 'y' )
  {
$cpe++;
push @required,$exchange;
#print Dumper ($exchange) ;
print $exchange->as_string;
}
}
print "############################## fin dialogue minimal  #################################\n";

