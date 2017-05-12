use strict;
use warnings;
use utf8;

package ItalianTextGenerator;
use version; our $VERSION = qv('2.3.41');
sub new {
  my ( $classname ) = @_;
  my $self = {
    Prayer_for_the_living => "Prayer_for_the_living",
    Prayer_for_the_departed => "Prayer_for_the_departed",  
    members => "Membri della famiglia",
    Relatives => "Parenti",
    Faces => "Faccie",
    Surnames => "Cognomi",
    Homepages => "Siti internet",
    homepage => "Sito internet",
    Birthdays => "Compleanni",
    birthday => "compleanno",
    Error => "Errore",
    Sorry => "Scusi",
    Passwd_need => "Una passord è neccessario di accedere questo sito.",
    Wrong_passwd => "Password scorretta.",
    father => "padre",
    mother => "madre",
    nickname => "diminutivo",
    place_of_birth => "posto di nascita",
    place_of_death =>"posto di morte",
    cemetery => "cimitero",    
    schools => "scuole",
    jobs => "lavori",
    work_places => "posti di lavoro",
    places_of_living => "residenze",
    general => "generale",                
    
    siblings => "fratelli e sorelle",
    siblings_on_father => "fratellastri o sorellastre da parte del padre",
    siblings_on_mother => "fratellastri o sorellastre da parte della madre ",
    children => "bambini",
    spouses => "consorti",
    husbands => "sposi",
    wives => "moglie",    
    
    date_of_birth => "data di nascita",
    date_of_death => "data di morte",
    Total => "In tutto",
    people => "gente",
    Emails => "Emaili",
    email => "email",
    Hall_of_faces => "Galleria di ritratti",
    Total_with_email => "Numero di parenti con email indrizzo: ",
    Total_with_homepage => "Numero di parenti con sito internet: ",
    Total_with_photo => "Numero di parenti con ritratto: ",
    months_array => [ "Gennaio", "Febbraio", "Marzo", "Aprile", "Maggio", "Giugno",
      "Luglio",    "Agosto",   "Settembre", "Ottobre", "Novembre", "Dicembre"],
    Invalid_option => "Il valore del parametro 'type' è invalido",
    Valid_options => "I valori possibili per il parametro 'type': <vuoto>, snames, faces, emails, hpages, bdays.",
    ZoomIn => "Zoom in", 
    ZoomOut => "Zoom out",
    CheckAnotherMonth => "Mostrare un altro giorno",
    DonationSentence => "Questo programma è assolutamente gratuito, ma vostro supporto è necessario di mantenerlo e svilupparlo.", 
    Go => "Avanti",
    Unknown => "Sconosciuto",
    name => "nome",
    photo => "foto",
    man => "uomo",
    woman => "donna",
    unknown => "sconosciuto",    

    hungarian => "ungherese",    
    polish => "polacco",
    english => "inglese",
    german => "tedesco",
    spanish => "spagnolo",
    italian => "italiano",    
    french => "francese", 
    slovenian => "slovenese",
    romanian => "romeno",
    russian => "russo",    
    japanese => "giapponese",
    chinese => "cinese",               
  };
  return bless $self, $classname;
}

sub summary{
  my ($self, $nr_people) = @_;
  return "In tutto: $nr_people gente.\n";
}
sub maintainer{
    my ($self, $admin_name, $admin_email, $admin_webpage) = @_;
    my $text;
    $text = "I dati nel albero genealogico è mantenuto da "; 
    if(defined $admin_webpage) {
      $text .= "<a href=\"".$admin_webpage."\" target=\"_new\">".$admin_name."</a>";
    }
    else{
      $text .= $admin_name;
    }
    $text .= ". Per favore, in caso di qualunque errore, mandi un <a href=\"mailto:$admin_email\">email</a>."; 
}
sub software{
  my ($self, $version) = @_;
  return "Il programma d'albero genealogico (ver. $version) è sviluppato da <a href=\"http://www.cs.bme.hu/~bodon/magyar/index.html\" target=\"_new\">Ferenc Bodon</a> e ".
  "<a href=\"http://simonward.com/\"  target=\"_new\">Simon Ward</a>  and
  <a href=\"http://mishin.narod.ru/\"  target=\"_new\">Nikolay Mishin</a> . Per più particolari, visitate <a href=\"http://freshmeat.net/projects/familytree_cgi/\">il sito</a>.\n"; 
}
sub People_with_surname {
  my ($self, $surname) = @_;
  return "Parenti con il cognome ".$surname;
}

sub noDataAbout {
  my ($self, $id) = @_;
  return "ERRORE: No nota esiste con l'identificazione $id.";
}
sub familyTreeFor {
    my ($self, $name) = @_;
    return "L'albero genealogico di $name";
}
sub ZoomIn {
  my ($self, $level) = @_;
  return "Zoom in: mostrare non più di $level generazioni.";
}
sub ZoomOut {
  my ($self, $level) = @_;
  return "Zoom out: mostrare $level generazioni.";
}
sub birthday_reminder {
    my ($self, $month_index) = @_;
    return "Promemorie di compleanno per ".$self->{months_array}[$month_index];
}
sub total_living_with_birthday {
    my ($self, $month_index) = @_;
    return "Parenti vivi con il compleanno in ".$self->{months_array}[$month_index];
}
1;
