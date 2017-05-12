use strict;
use warnings;
use utf8;

package FrenchTextGenerator;
use version; our $VERSION = qv('2.3.41');
sub new {
  my ( $classname ) = @_;
  my $self = {
    Prayer_for_the_living => "Prayer_for_the_living",
    Prayer_for_the_departed => "Prayer_for_the_departed",  
    members => "Les membres de la famille",
    Relatives => "Parenté",
    Faces => "Visages",
    Surnames => "Noms de famille",
    Homepages => "Pages d'accueil",
    homepage => "page d'accueil",
    Birthdays => "Anniversaires",
    birthday => "anniversaire",
    Error => "Erreur",
    Sorry => "Désolé",
    Passwd_need => "Vous avez besoin d'un mot de passe pour visiter cette page.",
    Wrong_passwd => "Vous avez donné un mauvais mot de passe.",
    father => "père",
    mother => "mère",
    nickname => "surnom",
    place_of_birth => "lieu de naissance",
    place_of_death =>"lieu de décès",
    cemetery => "cimetière",
    schools => "écoles",
    jobs => "emplois",
    work_places => "lieux de travail",
    places_of_living => "domiciles",
    general => "général",
    
    siblings => "frères et soeurs",
    siblings_on_father => "demi-frères et demi-soeurs de père",
    siblings_on_mother => "demi-frères et demi-soeurs de mère",
    children => "enfants",
    spouses => "époux",
    husbands => "maris",
    wives => "femmes",    
    
    date_of_birth => "date de naissance",
    date_of_death => "date de décés",
    Total => "En total",
    people => "personnes",
    Emails => "Courriers électroniques",
    email => "courrier électronique",
    Hall_of_faces => "Galerie des visages",
    Total_with_email => "Nombre total de personnes ayant un courrier électronique: ",
    Total_with_homepage => "Nombre total de personnes ayant une page d'accueil: ",
    Total_with_photo => "Nombre total de personnes ayant une photo: ",
    months_array => [ "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
      "Juillet",    "Août",   "Séptembre", "Octobre", "Novembre", "Décembre"],
    Invalid_option => "Valeur inapproprié de type paramètre",
    Valid_options => "Les valeurs possibles de type paramètre sont: <vide>, snames, faces, emails, hpages, bdays.",
    ZoomIn => "Zoomer",
    ZoomOut => "Dézoomer",
    CheckAnotherMonth => "Regarder un autre mois",
    DonationSentence => "Le logiciel de l'arbre généalogique est totalement gratuit. Cependant pour l'entretenir les donations sont bienvenus",
    Go => "Lancer",
    Unknown => "Inconnu",
    name => "nom",
    photo => "photo",
    man => "hommes",
    woman => "femmes",
    unknown => "inconnu",    

    hungarian => "hongrois",    
    polish => "polnisch",
    english => "anglais",
    german => "allemand",
    spanish => "espagnol",
    italian => "italien",    
    french => "français",
    slovenian => "Slovène",
    romanian => "roumain",
    russian => "russe",
    japanese => "japonais",
    chinese => "chinois",
  };
  return bless $self, $classname;
}

sub summary{
  my ($self, $nr_people) = @_;
  return "En total: $nr_people personnes.\n";
}
sub maintainer{
    my ($self, $admin_name, $admin_email, $admin_webpage) = @_;
    my $text;
    $text = "Le base de données de l'arbre généalogique est géré par";
    if(defined $admin_webpage) {
      $text .= "<a href=\"".$admin_webpage."\" target=\"_new\">".$admin_name."</a>";
    }
    else{
      $text .= $admin_name;
    }
    $text .= "  - veuillez envoyer vos remarques par <a href=\"mailto:$admin_email\">courrier électronique</a>.";
}
sub software{
  my ($self, $version) = @_;
  return "Le logiciel de l'arbre généalogique (ver. $version) est écrit par <a href=\"http://www.cs.bme.hu/~bodon/magyar/index.html\" target=\"_new\">Ferenc Bodon</a> et ".
  "<a href=\"http://simonward.com/\"  target=\"_new\">Simon Ward</a>  and
  <a href=\"http://mishin.narod.ru/\"  target=\"_new\">Nikolay Mishin</a> - pour des informations détaillées veuillez visiter son <a href=\"http://freshmeat.net/projects/familytree_cgi/\">site internet</a>.\n";
}
sub People_with_surname {
  my ($self, $surname) = @_;
  return " Parents avec le nom de famille".$surname;
}

sub noDataAbout {
  my ($self, $id) = @_;
  return "ERREUR: aucune entrée avec un ID $id !";
}
sub familyTreeFor {
    my ($self, $name) = @_;
    return "L'arbre généalogique de $name";
}
sub ZoomIn {
  my ($self, $level) = @_;
  return "Zoomer: montrer pas plus que $level générations au-dessus et au-dessous.";
}
sub ZoomOut {
  my ($self, $level) = @_;
  return "Dézoomer: montrer même $level générations au-dessus et au-dessous.";
}
sub birthday_reminder {
    my ($self, $month_index) = @_;
    return "Rappel de l'anniversaire au ".$self->{months_array}[$month_index];
}
sub total_living_with_birthday {
    my ($self, $month_index) = @_;
    return "Nombre de personnes vivants dont l'anniversaire est au: ".$self->{months_array}[$month_index]; 
}
1;
