use strict;
use warnings;

package RomanianTextGenerator;
use version; our $VERSION = qv('2.3.41');
sub new {
  my ( $classname ) = @_;
  my $self = {
    Prayer_for_the_living => "Prayer_for_the_living",
    Prayer_for_the_departed => "Prayer_for_the_departed",
    members => "Membrii arborii genealogic", 
    Relatives => "Rude", 
    Faces => "Poze", 
    Surnames =>"Nume de familii", 
    Homepages => "Pagini web", 
    homepage => "pagina web", 
    Birthdays => "Zile de nastere", 
    birthday => "ziua de nastere", 
    Error => "Eroare", 
    Sorry => "Imi pare rau", 
    Passwd_need => "Parola este ceruta pentru vizualizarea acestor pagini.", 
    Wrong_passwd => "Parola gresita pentru aceste pagini.", 
    
    father => "tata", 
    mother => "mama", 
    nickname => "porecla", 
    place_of_birth => "locul nasterii", 
    place_of_death =>"locul decesului", 
    cemetery => "cimitir",
    schools => "scoli", 
    jobs => "functii",
    work_places => "locuri de munca", 
    places_of_living => "domicilii", 
    general => "general",
    
    siblings => "frati/surori",
    siblings_on_father => "frati vitregi din partea tatalui", 
    siblings_on_mother => "frati vitregi din partea mamei", 
    children => "copii", 
    husbands => "soti",
    wives => "neveste", 
    
    date_of_birth => "data nasterii", 
    date_of_death => "data decesului", 
    Total => "Total", 
    people => "oameni",
    Emails => "Emailuri", 
    email => "email", 
    Hall_of_faces => "Galeria de poze",
    Total_with_email => "Numari total de oamneni cu adresa email:", 
    Total_with_homepage => "Numari total de oamneni cu pagina web:",
    Total_with_photo => "Numari total de oamneni cu poza:", 

    months_array => [ "Januarie", "Februarie", "Martie", "Aprilie", "Mai", "Junie",
      "Julie",    "August",   "Septembrie", "Octombrie", "Noiembrie", "Decembrie"],


    Invalid_option => "Parameter de invalid tip", 
    Valid_options => "Optiuni posibile sunt: <none>, snames, faces, emails, hpages, bdays. ",
    ZoomIn => "Marire",
    ZoomOut => "Micsorare",
    CheckAnotherMonth => "Incerati alta luna", 
    DonationSentence => "Programul arborele genealogic este absolut gratis. Totusi pentru intretinere si dezvoltare donatii sunt necesare.",
    Go => "Start",
    Unknown => "Necunoscut", 
    name => "nume", 
    photo => "poza",
    man => "barbat", 
    woman => "femeie", 
    unknown => "necunoscut", 

    hungarian => "maghiar",
    polish => "plonez",   
    english => "englez",
    german => "german",
    spanish => "spaniol",
    italian => "italian",
    french => "francez",
    slovenian => "sloven",
    romanian => "roman",
    russian => "rusesc",
    japanese => "japonez",
    chinese => "chinez",
  };
  return bless $self, $classname;
}

sub summary{
  my ($self, $nr_people) = @_;
  return "Total: $nr_people people \n";
}
sub maintainer {
    my ($self, $admin_name, $admin_email, $admin_webpage) = @_;
    my $text;
    $text = "Date de familie intretinut de ";
    if(defined $admin_webpage) {
      $text .= "<a href=\"".$admin_webpage."\" target=\"_new\">".$admin_name."</a>";
    }
    else{
      $text .= $admin_name;
    }
    $text .= "- va rog <a href=\"mailto:$admin_email\">trimiteti email</a> pentru orice omisiune sau cortectii.";

}

sub software {
  my ($self, $version) = @_;

  return "Software pentru arbore de famile (ver. $version) by <a href=\"http://www.cs.bme.hu/~bodon/en/index.html\" target=\"_new\">Ferenc Bodon</a> and ".
  "<a href=\"http://simonward.com/\"  target=\"_new\">Simon Ward</a> and
  <a href=\"http://mishin.narod.ru/\"  target=\"_new\">Nikolay Mishin</a>  - <a href=\"http://freshmeat.net/projects/familytree_cgi/\">detalii</a>.\n";


}

sub People_with_surname {
  my ($self, $surname) = @_;
  return "Rude cu nume de familie $surname";
}
 
sub noDataAbout {
  my ($self, $id) = @_;
  return "ERROR: Nu s-a gasit record pentru $id";

}

sub familyTreeFor {
    my ($self, $name) = @_;
    return "Arobore de familie pentru $name";
}

sub ZoomIn {
  my ($self, $level) = @_;
  return "Marire: vizualizare cel mult $level genreratii.";
}

sub ZoomOut {
  my ($self, $level) = @_;
  return "Micsorare: vizualizare pana la $level generatii.";
}
sub birthday_reminder {
    my ($self, $month_index) = @_;
    return "Amintitor pentru ziua de nastere " . $self->{months_array}[$month_index];
}

sub total_living_with_birthday {
    my ($self, $month_index) = @_; 
    return "Numar total de rude cu data nasterii in " . $self->{months_array}[$month_index].": "; 
}

1;
