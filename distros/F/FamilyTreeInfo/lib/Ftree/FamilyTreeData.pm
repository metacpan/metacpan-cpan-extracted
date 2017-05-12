package Ftree::FamilyTreeData;
use strict;
use warnings;
use version; our $VERSION = qv('2.3.41');

use Ftree::Person;
use Ftree::Name;
use Ftree::DataParsers::FieldValidatorParser;
use Params::Validate qw(validate
    SCALAR
    ARRAYREF
    HASHREF
    CODEREF
    GLOB
    GLOBREF
    SCALARREF
    HANDLE
    BOOLEAN
    UNDEF
    OBJECT
);
# use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Sub::Exporter -setup => { exports => [ qw(new add_person) ] };

sub new{
  my ( $classname) = @_;
  my $self = {
    people   => {},  #hash of Person
  };
  return bless $self, $classname;
}
sub add_person{
  my ($self) = shift;
  my (%arg_ref) = validate(@_, { id => {type => SCALAR},
    first_name => {type => SCALAR|UNDEF, default => undef },
    mid_name   => {type => SCALAR|UNDEF, default => undef},
    last_name  => {type => SCALAR|UNDEF, default => undef},
    title      => {type => SCALAR|UNDEF, default => undef},
    prefix     => {type => SCALAR|UNDEF, default => undef},
    suffix     => {type => SCALAR|UNDEF, default => undef},
    nickname   => {type => SCALAR|UNDEF, default => undef},
    father_id  => {type => SCALAR|UNDEF, default => undef},
    mother_id  => {type => SCALAR|UNDEF, default => undef},
    email      => {type => SCALAR|UNDEF, default => undef},
    homepage   => {type => SCALAR|UNDEF, default => undef},
    date_of_birth=> {type => SCALAR|UNDEF, default => undef},
    date_of_death=> {type => SCALAR|UNDEF, default => undef},
    gender     => {type => SCALAR|UNDEF, default => undef},
    is_living  => {type => SCALAR|UNDEF, default => undef},
    place_of_birth => {type => SCALAR|UNDEF, default => undef},
    place_of_death => {type => SCALAR|UNDEF, default => undef},
    cemetery   => {type => SCALAR|UNDEF, default => undef},
    schools    => {type => ARRAYREF|UNDEF, default => undef},
    jobs       => {type => ARRAYREF|UNDEF, default => undef},
    work_places => {type => ARRAYREF|UNDEF, default => undef},
    places_of_living => {type => SCALAR|UNDEF, default => undef},
    general    => {type => SCALAR|UNDEF, default => undef} });

  if(!Ftree::DataParsers::FieldValidatorParser::validIDEntry($arg_ref{id})) {
    die "Not valid Id: " . $arg_ref{id} . " Ids should not contain "
      . "only alphanumeric plus underscore character";
    return;
  }

  if ( !defined $self->{people}{ $arg_ref{id} } ) {
  	$self->{people}{ $arg_ref{id} } = Ftree::Person->new( {id => $arg_ref{id}} );
  }
  my $temp_person = $self->{people}{ $arg_ref{id} };
  $temp_person->set_is_living(1);

  $temp_person->set_name(Ftree::Name->new(
          {first_name => $arg_ref{first_name},
           mid_name   => $arg_ref{mid_name},
           last_name  => $arg_ref{last_name}}));
  $temp_person->get_name()->set_title($arg_ref{title})
    if(defined $arg_ref{title});
  $temp_person->get_name()->set_prefix($arg_ref{prefix})
    if(defined $arg_ref{prefix});
  $temp_person->get_name()->set_suffix($arg_ref{suffix})
    if(defined $arg_ref{suffix});
  $temp_person->get_name()->set_nickname($arg_ref{nickname})
    if(defined $arg_ref{nickname});

  $self->set_parent($temp_person, $arg_ref{father_id}, 0);
  $self->set_parent($temp_person, $arg_ref{mother_id}, 1);

  if(defined $arg_ref{email} && $arg_ref{email} ne "") {
    if(Ftree::DataParsers::FieldValidatorParser::validEmail($arg_ref{email})) {
      $temp_person->set_email($arg_ref{email});
    } else {
      die 'Not valid email: ' . $arg_ref{email};
    }
  }

  if(defined $arg_ref{homepage} && $arg_ref{homepage} ne "") {
    if(Ftree::DataParsers::FieldValidatorParser::validURL($arg_ref{homepage})) {
      $temp_person->set_homepage($arg_ref{homepage});
    } else {
      die 'Not valid url: ' . $arg_ref{homepage};
    }
  }

  $temp_person->set_date_of_birth(Ftree::DataParsers::FieldValidatorParser::getDate($arg_ref{date_of_birth}))
    if ( defined $arg_ref{date_of_birth}
         && Ftree::DataParsers::FieldValidatorParser::getDate($arg_ref{date_of_birth}) );
   if ( defined $arg_ref{date_of_death}
        && Ftree::DataParsers::FieldValidatorParser::getDate($arg_ref{date_of_death})) {
         $temp_person->set_date_of_death(Ftree::DataParsers::FieldValidatorParser::getDate($arg_ref{date_of_death}));
         $temp_person->set_is_living(0);
   }


  if(defined $arg_ref{gender} && $arg_ref{gender} ne "") {
    if(Ftree::DataParsers::FieldValidatorParser::validBool($arg_ref{gender})) {
      $temp_person->set_gender($arg_ref{gender});
    } else {
      die "Not valid bool: " . $arg_ref{gender};
    }
  }

   my $place = Ftree::DataParsers::FieldValidatorParser::getPlace($arg_ref{place_of_birth});
   $temp_person->set_place_of_birth($place)
     if(defined $arg_ref{place_of_birth});

   $place = Ftree::DataParsers::FieldValidatorParser::getCemetery($arg_ref{cemetery});
   if(defined $place) {
     $temp_person->set_cemetery($place);
     $temp_person->set_is_living(0);
   }

   $temp_person->set_schools($arg_ref{schools})
     if(defined $arg_ref{schools});
   $temp_person->set_jobs($arg_ref{jobs})
     if(defined $arg_ref{jobs});
   $temp_person->set_work_places($arg_ref{work_places})
     if(defined $arg_ref{work_places});
   $temp_person->set_places_of_living(
     Ftree::DataParsers::FieldValidatorParser::getPlacesArray($arg_ref{places_of_living}))
       if(defined $arg_ref{places_of_living});
   $temp_person->set_general($arg_ref{general})
     if(defined $arg_ref{general});

  if(defined $arg_ref{is_living} && $arg_ref{is_living} ne "") {
    if(Ftree::DataParsers::FieldValidatorParser::validBool($arg_ref{is_living})) {
      if(0 == $temp_person->get_is_living() && $arg_ref{is_living}){
      	die "is_living field should be 0 for " . $arg_ref{id};
      } else {
      	$temp_person->set_is_living($arg_ref{is_living});
      }
    } else {
      die "Not valid bool: " . $arg_ref{is_living};
    }
  }


  return $temp_person;
}
sub get_person {
  my ($self, $id) = @_;

  return $self->{people}{$id};
}
sub get_all_people {
  my $self = shift;
  return values %{$self->{people}};
}

sub set_parent {
  my ($self, $temp_person, $id, $gender) = @_;
  return unless defined $id;

  if(!Ftree::DataParsers::FieldValidatorParser::validIDEntry($id)) {
  	die "Not valid Id: $id. Ids should not contain " .
         "only alphanumeric plus underscore character!";
    return;
  }
  if ( !defined $self->{people}{ $id } ) {
    $self->{people}{ $id } = Ftree::Person->new( { id => $id } );
  }

  my $parent = $self->{people}{ $id };

  if($gender == 0) {
    $temp_person->set_father($parent);
  }
  else {
	$temp_person->set_mother($parent);
  }

  if ( !defined $parent->get_gender() ) {
    $parent->set_gender($gender);
  }
  else {
	die( "Incorrent gender for " . $parent->get_id() )
	  if ( $parent->get_gender() != $gender );
  }

  if (defined $parent->get_children()) {
    push @{$parent->get_children()}, $temp_person;
  }
  else {
	$parent->set_children([$temp_person]);
  }

  return;
}


1;
