package Ftree::DataParsers::GedcomFormat;
use strict;
use warnings;
use version; our $VERSION = qv('2.3.41');
use Gedcom;
use Ftree::DataParsers::FieldValidatorParser;
use Ftree::FamilyTreeData;
# use CGI::Carp qw(fatalsToBrowser);
use Encode qw(decode_utf8);

my %genderTogedcomsex = (
  U => undef,
  F => 1,
  M => 0,
);

my %montharray = (
  JAN => 1,
  FEB => 2,
  MAR => 3,
  APR => 4,
  MAY => 5,
  JUN => 6,
  JUL => 7,
  AUG => 8,
  SEP => 9,
  OCT => 10,
  NOV => 11,
  DEC => 12,
  
  
);
 
sub createFamilyTreeDataFromFile {
  my ($config_) = @_;
  my $file_name = $config_->{file_name} or die "No file_name is given in config";

  my $ged = Gedcom->new(gedcom_file  => $file_name);
  my $family_tree_data = Ftree::FamilyTreeData->new();                        
  for my $i ($ged->individuals)
  {
    $family_tree_data->add_person({
          id => $i->{xref},
          first_name => decode_utf8($i->given_names(0)),
          mid_name   => undef,
          last_name  => decode_utf8($i->surname),
          father_id  => (defined $i->father) ? decode_utf8($i->father->{xref}) : undef,
          mother_id  => (defined $i->mother) ? decode_utf8($i->mother->{xref}) : undef,
          email      => getEmail($i),
          homepage   => getHomepage($i),
          date_of_birth => getDate("birth date", $i),          
          date_of_death => getDate("death date", $i),
          gender     => $genderTogedcomsex{$i->sex()},
          place_of_birth => getPlace("birth place", $i),
          place_of_death => getPlace("death place", $i),
          cemetery   => getPlace("burial place",$i),
    })
   }
  return $family_tree_data;                         
}

sub getDate {
  my ($date_type, $i) = @_;
    my $date = $i->get_value($date_type);
    if(defined $date) {
      $date = (split(/, /, $date))[-1];  #separated by comma, whitespace pair
      my @date_a = split(/ /, $date);
      if(2 < @date_a) {
        $date_a[1] = $montharray{$date_a[1]} ;	
      } elsif (1 < @date_a) {
      	$date_a[0] = $montharray{$date_a[0]} ;
      }      
      return join('/', @date_a);             
    }
    return undef;
}
sub getPlace {
  my ($place_type, $i) = @_;
  my $place = decode_utf8($i->get_value($place_type));
  if(defined $place) {
    $place =~ s/, /" "/g;  #separated by comma, whitespace pair 
    $place =~ s/^/"/g;
    $place =~ s/$/"/g;
    return $place;
  }
  return undef;
}

sub getEmail {
  my ($i) = @_;
  my @data = decode_utf8($i->get_value("Object File"));
  my @emails = grep {defined $_ && FieldValidatorParser::validEmail($_)} @data; 
  return $emails[0];

}
sub getHomepage {
  my ($i) = @_;
  my @data = decode_utf8($i->get_value("Object File"));
  my @urls = grep {defined $_ && FieldValidatorParser::validURL($_)} @data; 
  return $urls[0];

}

1;
