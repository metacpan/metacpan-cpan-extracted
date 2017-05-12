use strict;
use warnings;
use utf8;

package PolishTextGenerator;
use version; our $VERSION = qv('2.3.41');

sub new {
  my ( $classname ) = @_;
  my $self = {
    Prayer_for_the_living => "Prayer_for_the_living",
    Prayer_for_the_departed => "Prayer_for_the_departed",
    members => "Członek rodziny",
    Relatives => "Relacje",
    Faces => "Zdjęcia",
    Surnames =>"Nazwiska",
    Homepages => "Strony WWW",
    homepage => "strona WWW",
    Birthdays => "Urodziny",
    birthday => "urodziny",
    Error => "Błąd",
    Sorry => "Przepraszamy",  
    Passwd_need => "Musisz wprowadzić hasło aby móc oglądać strony.",
    Wrong_passwd => "Zostało wpisane niepoprawne hasło.",
    
    father => "ojciec",
    mother => "matka",
    nickname => "pseudonim",
    place_of_birth =>"miejsce urodzenia",
    place_of_death =>"miejsce śmierci",
    cemetery => "cmentarz",
    schools => "szkoły",
    jobs => "wykonywane zawody",
    work_places => "miejsca pracy",
    places_of_living => "miejsca zamieszkania",
    general => "ogólne", 
                
    siblings => "rodzeństwo",
    siblings_on_father => "rodzeństwo ojca",
    siblings_on_mother => "rodzeństwo matki",
    children => "dzieci",
    husbands => "mężowie",
    wives => "żony",
    
    date_of_birth => "data urodzin",
    date_of_death => "data śmierci",
    Total => "Suma",
    people => "osoby",
    Emails => "Adresy e-mail",
    email => "adres e-mail",
    Hall_of_faces => "Galeria",
    Total_with_email => "Liczba posiadaczy adresów e-mail: ",
    Total_with_homepage => "Liczba posiadaczy stron WWW: ",
    Total_with_photo => "Liczba posiadaczy zdjęć: ",
    months_array => [ "Styczeń", "Luty", "Marzec", "Kwiecień", "Maj",
    "Czerwiec",
      "Lipiec",    "Sierpień",   "Wrzesień", "Październik", "Listopad",
      "Grudzień"],
    Invalid_option => "Niewłaściwy typ parametru",
    Valid_options => "Poprawne opcje to: <brak>, nazwiska, twarze, adresy
    e-mail, strony WWW, daty urodzin.",
    ZoomIn => "Przybliż",
    ZoomOut => "Oddal",
    CheckAnotherMonth => "Zmień na inny miesiąc",
		DonationSentence => "Oprogramiowanie famili tree jest całkowicie darmowe. Jednak aby utrzymać je przy życiu, potrzebne są darowizny",
    Go => "Dalej",
    Unknown => "Nieznany",
    name => "imię",
    photo => "zdjęcie",
    man => "mężczyzn",
    woman => "kobiet",
    unknown => "nieznanych",
    
    hungarian => "węgierski",
    polish => "polski",
    english => "angielski",
    german => "niemiecki",
    spanish => "hiszpański",
    italian => "włoski",
    french => "francuski",
    slovenian => "sloweński",
    romanian => "rumuński",
    russian => "rosyjski",
    japanese => "japoński",
    chinese => "chiński",

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
    if(defined $admin_webpage) {
      $text .= "<a href=\"".$admin_webpage."\" target=\"_new\">".$admin_name."</a>";
    }
    else{
      $text .= $admin_name;
    }
    $text .= " zarządza danymi rodziny.";
    $text .= "W razie zauważenia błędów proszę o kontakt na <a
    href=\"mailto:$admin_email\">adres e-mail</a>.";
}
sub software {
  my ($self, $version) = @_;
  return "Family tree software (ver. $version) by <a href=\"http://www.cs.bme.hu/~bodon/en/index.html\" target=\"_new\">Ferenc Bodon</a> and ".
  "<a href=\"http://simonward.com/\"  target=\"_new\">Simon Ward</a> and
  <a href=\"http://mishin.narod.ru/\"  target=\"_new\">Nikolay Mishin</a>  - <a href=\"http://freshmeat.net/projects/familytree_cgi/\">details</a>.\n";}

sub People_with_surname {
  my ($self, $surname) = @_;
  return "Osoby o nazwisku ".$surname;
} 
sub noDataAbout {
  my ($self, $id) = @_;
  return "Błąd: brak danych o $id";
}
sub familyTreeFor {
    my ($self, $name) = @_;
    return "Drzewo genealogiczne dla $name";
}
sub ZoomIn {
  my ($self, $level) = @_;
  return "Przygliż: pokaż nie więcej niż $level pokoleń.";
}
sub ZoomOut {
  my ($self, $level) = @_;
  return "Oddal: pokaż do $level pokoleń wstecz i w przód.";
}
sub birthday_reminder {
    my ($self, $month_index) = @_;
    return "Przypomnienie o urodzinach".$self->{months_array}[$month_index];
}

sub total_living_with_birthday {
    my ($self, $month_index) = @_;
    return "Liczba żyjących członków rodziny obchodzących urodziny w ".$self->{months_array}[$month_index].": "; 
}

1;
