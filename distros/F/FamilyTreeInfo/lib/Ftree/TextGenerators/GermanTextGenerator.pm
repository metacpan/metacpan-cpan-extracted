use strict;
use warnings;
use utf8;

package GermanTextGenerator;
use version; our $VERSION = qv('2.3.41');
sub new {
  my ( $classname ) = @_;
  my $self = {
    Prayer_for_the_living => "Prayer_for_the_living",
    Prayer_for_the_departed => "Prayer_for_the_departed",  
    members => "Familienmitglieder",
    Relatives => "Verwandten",
    Faces => "Gesichter",
    Surnames => "Nachnamen",
    Homepages => "Homepages",
    homepage => "homepage",
    Birthdays => "Geburtstage",
    Error => "Fehler",
    Sorry => "Sorry",
    Passwd_need => "Um die Seite sehen zu können benötigen Sie ein Passwort.",
    Wrong_passwd => "Sie haben ein falsches Passwort eingegeben.",
    father => "Vater",
    mother => "Mutter",
    nickname => "Spitzname",
    place_of_birth => "Geburtsort",
    place_of_death =>"Sterbeort",
    cemetery => "Friedhof",
    schools => "Schulen",
    jobs => "Berufe",    
    work_places => "Arbeitsplätze",
    places_of_living => "Wohnorte",
    general => "allgemein",        
    
    siblings => "Geschwister",
    siblings_on_father => "Halbgeschwister vaterlicher Seite",
    siblings_on_mother => "Halbgeschwister mutterlicher Seite",
    children => "Kinder",
    spouses => "Ehepartnern",
    husbands => "Ehemänner",
    wives => "Ehefrauen",
    
    date_of_birth => "Geburtsdatum",
    date_of_death => "Todesdatum",
    Total => "Insgesamt",
    people => "Leute",
    Emails => "Emails",
    email => "email",
    Hall_of_faces => "Portraitgalerie",
    Total_with_email => "Die Anzahl der Verwandten mit Emailadresse: ",
    Total_with_homepage => "Die Anzahl der Verwandten mit Homepage: ",
    Total_with_photo => "Die Anzahl der Verwandten mit Foto: ",
    months_array => [ "Januar", "Februar", "März", "April", "Mai", "Juni",
      "Juli",    "August",   "September", "Oktober", "November", "Dezember"],
    Invalid_option => "Falscher Parametertyp",
    Valid_options => "Die möglichen Parametertypen: <leer>, snames, faces, emails, hpages, bdays.",
    ZoomIn => "Vergrösserung",
    ZoomOut => "Verkleinerung",
    CheckAnotherMonth => "Besichtigung eines anderen Monats",
    DonationSentence => "Die Familien Stammbaum Software ist kostenlos. Über jede finanzielle Unterstützung bei der Entwicklung des Programms würden wir uns freuen.",
    Go => "Los",
    Unknown => "Unbekannt",
    name => "name",
    photo => "photo",
    man => "Mann",
    woman => "Frau",
    unknown => "unbekannt",
    
    hungarian => "ungarisch",   
    polish => "polnisch", 
    english => "englisch",
    german => "deutsch",
    spanish => "spanisch",
    italian => "italienisch",    
    french => "französisch",
    slovenian => "slowenisch",
    romanian => "rumänisch",
    russian => "russisch",
    japanese => "japanisch",
    chinese => "chinesisch",            
  };
  return bless $self, $classname;
}

sub summary{
  my ($self, $nr_people,) = @_;
  return "Insgesamt: $nr_people Leute \n";
}
sub maintainer{
    my ($self, $admin_name, $admin_email, $admin_webpage) = @_;
    my $text;
    $text = "Die Datenbank des Stammbaumes wird von ";
    if(defined $admin_webpage) {
      $text .= "<a href=\"".$admin_webpage."\" target=\"_new\">".$admin_name."</a>";
    }
    else{
      $text .= $admin_name;
    }
    $text .= " instandgehalten - schicken Sie bitte Ihre Bemerkungen per <a href=\"mailto:$admin_email\">Email</a>.";
}
sub software{
  my ($self, $version) = @_;
  return "Das Programm (ver. $version) wurde von <a href=\"http://www.cs.bme.hu/~bodon/en/index.html\" target=\"_new\">Ferenc Bodon</a> und ".
  "<a href=\"http://simonward.com/\"  target=\"_new\">Simon Ward</a>  and
  <a href=\"http://mishin.narod.ru/\"  target=\"_new\">Nikolay Mishin</a> entwickelt - für weitere Informationen besichtingen Sie ihre <a href=\"http://freshmeat.net/projects/familytree_cgi/\">Homepage</a>.\n";
}
sub People_with_surname {
  my ($self, $surname) = @_;
  return "Verwandte mit Vorname ".$surname;
}

sub noDataAbout {
  my ($self, $id) = @_;
  return "FEHLER: kein Eintritt mit dieser ID $id!";
}
sub familyTreeFor {
    my ($self, $name) = @_;
    return "Stammbaum von $name";
}
sub ZoomIn {
  my ($self, $level) = @_;
  return "Vergrösserung: nicht mehr als $level Generationen anzeigen.";
}
sub ZoomOut {
  my ($self, $level) = @_;
  return "Verkleinerung: sogar $level Generationen anzeigen.";
}
sub birthday_reminder {
    my ($self, $month_index) = @_;
    return "Erinnerung des Geburtsgtages im ".$self->{months_array}[$month_index];
}
sub total_living_with_birthday {
    my ($self, $month_index) = @_;
    return "Die Anzahl der Verwandten mit Geburtstag im ".$self->{months_array}[$month_index].": "; 
}
1;
