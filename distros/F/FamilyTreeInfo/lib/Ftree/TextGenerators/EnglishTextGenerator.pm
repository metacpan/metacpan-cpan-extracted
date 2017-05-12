use strict;
use warnings;

package EnglishTextGenerator;
use version; our $VERSION = qv('2.3.41');
sub new {
  my ( $classname ) = @_;
  my $self = {
    Prayer_for_the_living => "Prayer_for_the_living",
    Prayer_for_the_departed => "Prayer_for_the_departed",
    members => "Family tree members",
    Relatives => "Relatives",
    Faces => "Faces",
    Surnames =>"Surnames",
    Homepages => "Homepages",
    homepage => "homepage",
    Birthdays => "Birthdays",
    birthday => "birthday",
    Error => "Error",
    Sorry => "Sorry",  
    Passwd_need => "You must provide a password to see these pages.",
    Wrong_passwd => "You have given the wrong password for these pages.",
    
    father => "father",
    mother => "mother",
    nickname => "nickname",
    place_of_birth => "place of birth",
    place_of_death =>"place of death",
    cemetery => "cemetery",
    schools => "schools",
    jobs => "jobs",
    work_places => "work places",
    places_of_living => "places of living",
    general => "general",
    
    siblings => "siblings",
    siblings_on_father => "half siblings from father side",
    siblings_on_mother => "half siblings from mother side",
    children => "children",
    husbands => "husbands",
    wives => "wives",
    
    date_of_birth => "date of birth",
    date_of_death => "date of death",
    Total => "Total",
    people => "people",
    Emails => "Emails",
    email => "email",
    Hall_of_faces => "Hall of faces",
    Total_with_email => "Total number of people with email address: ",
    Total_with_homepage => "Total number of people with home page: ",
    Total_with_photo => "Total number of people with photo: ",
    months_array => [ "January", "February", "March", "April", "May", "June",
      "July",    "August",   "September", "October", "November", "December"],
    Invalid_option => "Invalid type parameter",
    Valid_options => "Valid options are <none>, snames, faces, emails, hpages, bdays.",
    ZoomIn => "Zoom in",
    ZoomOut => "Zoom out",
    CheckAnotherMonth => "Check another month",
    DonationSentence => "The family tree software is absolutely free. Nevertheless to keep it alive donations are needed.",
    Go => "Go",
    Unknown => "Unknown",
    name => "name",
    photo => "photo",
    man => "man",
    woman => "woman",
    unknown => "unknown",

    hungarian => "hungarian",
    polish => "polish",   
    english => "english",
    german => "german",
    spanish => "spanish",
    italian => "italian",
    french => "french",
    slovenian => "slovenian",
    romanian => "romanian",
    russian => "russian",
    japanese => "japanese",
    chinese => "chinese",
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
    $text = "Family data maintained by";
    if(defined $admin_webpage) {
      $text .= "<a href=\"".$admin_webpage."\" target=\"_new\">".$admin_name."</a>";
    }
    else{
      $text .= $admin_name;
    }
    $text .= "- please <a href=\"mailto:$admin_email\">email</a> any omissions or corrections.";
}
sub software {
  my ($self, $version) = @_;
  return "Family tree software (ver. $version) by <a href=\"http://www.cs.bme.hu/~bodon/en/index.html\" target=\"_new\">Ferenc Bodon</a> and ".
  "<a href=\"http://simonward.com/\"  target=\"_new\">Simon Ward</a> and
  <a href=\"http://mishin.narod.ru/\"  target=\"_new\">Nikolay Mishin</a> 
    - <a href=\"http://freshmeat.net/projects/familytree_cgi/\">details</a>.\n";
}
sub People_with_surname {
  my ($self, $surname) = @_;
  return "People with surname ".$surname;
} 
sub noDataAbout {
  my ($self, $id) = @_;
  return "ERROR: No entry found for $id";
}
sub familyTreeFor {
    my ($self, $name) = @_;
    return "Family tree for $name";
}
sub ZoomIn {
  my ($self, $level) = @_;
  return "Zoom in: show no more than $level generations.";
}
sub ZoomOut {
  my ($self, $level) = @_;
  return "Zoom out: show up to $level generations above and below.";
}
sub birthday_reminder {
    my ($self, $month_index) = @_;
    return "Birthday reminders for ".$self->{months_array}[$month_index];
}

sub total_living_with_birthday {
    my ($self, $month_index) = @_;
    return "Total number of living people with birthday in ".$self->{months_array}[$month_index].": "; 
}

1;
