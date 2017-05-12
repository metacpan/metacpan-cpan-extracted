#!/usr/bin/perl 
##  copyright eric german 2008

use Lemonldap::Portal::Script;
use Data::Dumper;my $file = shift;

use Template ;
use CGI;
use CGI::Cookie;

open FILE, "< $file";
my $cp         = 1;
my $flag_deb   = 0;
my $flag_quest = 0;
my $flag_resp  = 0;
my $echange;
my $question;
my $response;
my @des_echanges;
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
        $echange->set_tirade('response',$response);
         $echange->add_string("----------------------------------------Fin echange $echange->{numero}");
       push @des_echanges, $echange; 
       
       next;
    }
    if ( ( $flag_quest == 1 ) && ( $line =~ /^HTTP/ ) ) {
        $echange->set_tirade('question',$question);
        $echange->add_string('    ');
        $flag_quest = 0;
        $flag_resp  = 1;
    }

    if ( $flag_deb == 0 ) {
    #    print "je commence un echange: $cp \n";
        $echange = Lemonldap::Portal::Script::Echange->new( numero => $cp, requete => $line );
        $flag_deb = 1;
        undef $question;
        undef $response;
       next;
    }

    if ( !$line ) {
        if ( ( $flag_deb == 1 ) && ( $flag_quest == 0 ) ) {
      $echange->add_string('    ');
         
          $flag_quest = 1;
            next;
        }
        if ( ( $flag_deb == 1 ) && ( $flag_quest == 1 ) ) {
            $flag_quest = 0;
       $echange->add_string('    ');
        
           $flag_resp  = 1;
            next;
        }

    }
    if ( $flag_quest == 1 ) {
        if ( !$question ) {
            $question = Lemonldap::Portal::Script::Question->new();
            $echange->set_method($line);
        }
        else {
            $question->add_header($line);

        }
    #    print "on est dans question ech $cp\n";
    }
    if ( $flag_resp == 1 ) {
        if ( !$response ) {
            $echange->set_tirade('question',$question);
            $echange->set_ResponseCode($line);
            $response = Lemonldap::Portal::Script::Response->new();
        }
        else {
            $response->add_header($line);

        }

    #    print "on est dans reponse ech $cp\n";
    }
$echange->add_string($line); 
}

close FILE;
### marquage des echanges ###
for (@des_echanges ) {
my $echange= $_;
if ($echange->{response}->{headers}->[0] =~ /gif|css|jpeg|jpg|javascript/i ) {
   $echange->set_status('n'); }
       elsif ($echange->{responsecode} =~ /^4/) {  
    $echange->set_status('n') ;}
             else 

          { $echange->set_status('y'); 
}

}
my $cpe;
for (@des_echanges ) {
my $echange= $_;

if ($echange->{require} eq 'y' )
  {
$cpe++;
push @required,$echange;
#print Dumper ($echange) ;
print $echange->as_string;
}
}
print "############################## fin dialogue minimal  #################################\n";



##### debut generation du programme ;
my $target;
my $method;
my $NAMESERVER= "a completer";
my $flag_test= 0; 
my $tt= Template->new(ABSOLUTE => 1,
                      POST_CHOMP =>1, );
my $output ;
my %variables ;
my $premier_echange = $required[0];
print "############################## debut config apache   #################################\n";
$variables{'nameserver'} =$NAMESERVER;
my $fich_template= "/root/robot_apache_conf.templ";
my $sortie= $tt->process($fich_template,\%variables,\$output) ;


my %les_cookies;
if ($flag_test ==1) {
 $variables{'agent'} = $premier_echange->{question}
          ->{headers_test}->[0] ;

}  else {
 $variables{'agent'} = 'onfly' ;
 }
my %h ;
for (@{$premier_echange->{question}->{headers}})
 { 
  (my $key, my $value) = /(.+)#(.+)/ ;
   $h{$key} = $value;
}
$variables{'list_HQ'} = \%h; ;



 $fich_template= "/root/robot_entete.templ";
 $sortie= $tt->process($fich_template,\%variables,\$output) ;
#$target = $premier_echange->{requete};
#$method = lc($premier_echange->{method});


$html= $output;
########  boucle de lecture 
my $controle=1 ;
my $cp=0;
my %h_cookies;
while ($controle ==1)  {
my $echange= shift @required ;
last if !$echange; 

if ($target ne 'redirection') 
{
 $variables{target}= $echange->{requete} ;
 $fich_template="/root/robot_redirection.templ";
 $tt->process($fich_template,\%variables,\$output) ;
 $html.= $output;
} 
$method = lc($echange->{method});
$variables{'method'} = $method;
$variables{'numero'} = $echange->{numero} ;

if ($method eq 'get' ) {
$fich_template="/root/robot_question.templ";
} else
   { 
  my $line_data = $echange->{question}->{DATA}[0];
  my %hashdata;
   my @tmp_data= split /&/ , $line_data;
   for (@tmp_data) {
     (my $var)= /(.+)=/;
     (my $val)= /=(.+)/;
    my $nom =$var;
    $nom =~ s/\./__/g;
     $hashdata{$nom} = $val ;    

#########################################################
    } 
  
 $variables{list_DATA}= \%hashdata;
 $fich_template="/root/robot_data.templ";
 $tt->process($fich_template,\%variables,\$output);
 $fich_template="/root/robot_suite.templ"; 
 }
$tt->process($fich_template,\%variables,\$output) ;
$html.= $output;


### prendre LES COOKIES de la reponse 
## uniquement si la reponse en contient 
my $tmp_cook;
 if ($echange->{response}->{headers_test}) {
    for (@{$echange->{response}->{headers_test}})
 { 
  (my $key, my $value) = /(.+)#(.+)/ ;
  if ($key =~ /set-cookie/i) {
   #$les_cookies{$key} = $value;
   my(@pairs) = split("; ?",$value );
   (my $name,my $value)= $pairs[0]=~  /(.+?)=(.+)/; 
#                       
   $h_cookies{$name} = 1;  

   $tmp_cook .= $pairs[0].";" ;
    }  
 
  }
#%les_cookies = parse CGI::Cookie($tmp_cook);      
} 
my @cooks;
for (keys %h_cookies) {
if ($h_cookies{$_} ==1 ) {
push @cooks , $_;
$h_cookies{$_}=0;
}
}
if (@cooks ) {
$variables{cookienames} = \@cooks;
$fich_template="/root/robot_cookies.templ";
$tt->process($fich_template,\%variables,\$output) ;
$html.= $output;
}


$target="";
# Les ajouter au header questions 
#### if code retour =200 et qu il reste des questions :next
if ($echange->{responsecode} == 302 ) {
  # generer la location et la methode 
$fich_template="/root/robot_response.templ";
$tt->process($fich_template,\%variables,\$output) ;
$html.=$output; 
   $method= 'get' ; 
  $target='redirection';
}
#### if code retour =300 on prend la relocation et on continue la boucle
### si plus d occurs on sort de la boucle


}
## fin scenario 
### je genere les cookies pour le client
$fich_template="/root/robot_fin_programme.templ";
$tt->process($fich_template,\%variables,\$output) ;

 

print "##############################debut programme perl  #################################\n";
print "$output\n";
#print Dumper(@des_echanges);
