use strict;
use warnings;
use utf8;

package HungarianTextGenerator;
use version; our $VERSION = qv('2.3.41');
sub new {
  my ( $classname ) = @_;
  my $self = {
    Prayer_for_the_living => "Prayer_for_the_living",
    Prayer_for_the_departed => "Prayer_for_the_departed",  
    members => "A család tagjai",
    Relatives => "Rokonok",
    Faces => "Arcok",
    Surnames => "Vezetéknevek",
    Homepages => "Honlapok",
    homepage => "Honlap",
    Birthdays => "Születésnapok",
    birthday => "születésnap",
    Error => "Hiba",
    Sorry => "Sajnálom",
    Passwd_need => "Az oldal megtekintéséhez jelszó szükséges.",
    Wrong_passwd => "Rossz jelszót adott meg.",
    father => "apa",
    mother => "anya",
    nickname => "becenév",
    place_of_birth => "születési hely",
    place_of_death =>"halálozási hely",
    cemetery => "temető",    
    schools => "iskolák",
    jobs => "munkák",
    work_places => "munkahelyek",
    places_of_living => "lakhelyek",
    general => "általános",                
    
    siblings => "testvérek",
    siblings_on_father => "féltestvérek apai oldalról",
    siblings_on_mother => "féltestvérek anyai oldalról",
    children => "gyerekek",
    spouses => "házastársak",
    husbands => "férjek",
    wives => "feleségek",    
    
    date_of_birth => "születési dátum",
    date_of_death => "halálozási dátum",
    Total => "Összesen",
    people => "ember",
    Emails => "Emailek",
    email => "email",
    Hall_of_faces => "Arcképcsarnok",
    Total_with_email => "Email címmel rendelkező rokonok száma: ",
    Total_with_homepage => "Honlappal rendelkező rokonok száma: ",
    Total_with_photo => "Fényképpel rendelkező rokonok száma: ",
    months_array => [ "Január", "Február", "Március", "Április", "Május", "Június",
      "Július",    "Augusztus",   "Szeptember", "Október", "November", "December"],
    Invalid_option => "Helytelen type paraméter érték",
    Valid_options => "A lehetséges type paraméterek: <üres>, snames, faces, emails, hpages, bdays.",
    ZoomIn => "Nagyítás",
    ZoomOut => "Kicsinyítés",
    CheckAnotherMonth => "Másik nap megtekintése",
    DonationSentence => "A családfa program teljesen ingyenes. Életben maradásához és fejlődéséhez azonban támogatásra van szükség.",
    Go => "Mehet",
    Unknown => "Ismeretlen",
    name => "név",
    photo => "fénykép",
    man => "férfi",
    woman => "nő",
    unknown => "ismeretlen",    

    hungarian => "magyar", 
    polish => "lengyel",   
    english => "angol",
    german => "német",
    spanish => "spanyol",
    italian => "olasz",    
    french => "francia", 
    slovenian => "szlovén",
    romanian => "román",
    russian => "orosz",
    japanese => "japán",
    chinese => "kínai",               
  };
  return bless $self, $classname;
}

sub summary{
  my ($self, $nr_people) = @_;
  return "Összesen: $nr_people ember.\n";
}
sub maintainer{
    my ($self, $admin_name, $admin_email, $admin_webpage) = @_;
    my $text;
    $text = "A családfa adatállományát ";
    if(defined $admin_webpage) {
      $text .= "<a href=\"".$admin_webpage."\" target=\"_new\">".$admin_name."</a>";
    }
    else{
      $text .= $admin_name;
    }
    $text .= " tartja karban - kérem <a href=\"mailto:$admin_email\">emailben</a> küldjék el észrevételeiket.";
}
sub software{
  my ($self, $version) = @_;
  return "A családfa programot  (ver. $version) <a href=\"http://www.cs.bme.hu/~bodon/magyar/index.html\" target=\"_new\">Bodon Ferenc</a> és ".
  "<a href=\"http://simonward.com/\"  target=\"_new\">Simon Ward</a>  and
  <a href=\"http://mishin.narod.ru/\"  target=\"_new\">Nikolay Mishin</a> írta - további részletekért látogassanak el a <a href=\"http://freshmeat.net/projects/familytree_cgi/\">weboldalára</a>.\n";
}
sub People_with_surname {
  my ($self, $surname) = @_;
  return $surname." vezetéknevű rokonok";
}

sub noDataAbout {
  my ($self, $id) = @_;
  return "HIBA: $id azonosítóval nincs bejegyzés!";
}
sub familyTreeFor {
    my ($self, $name) = @_;
    return "$name családfája";
}
sub ZoomIn {
  my ($self, $level) = @_;
  return "Nagyítás: nem több, mint $level generáció megjelenítése felfelé és lefelé.";
}
sub ZoomOut {
  my ($self, $level) = @_;
  return "Kicsinyítés: akár $level generáció megrajzolása.";
}
sub birthday_reminder {
    my ($self, $month_index) = @_;
    return $self->{months_array}[$month_index]."i születésnap-emlékeztető";
}
sub total_living_with_birthday {
    my ($self, $month_index) = @_;
    return "A ".$self->{months_array}[$month_index]
      ."i születésnappal rendelkező élő rokonok száma: "; 
}
1;
