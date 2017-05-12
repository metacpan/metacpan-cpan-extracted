package Ftree::Person;
use strict;
use warnings;
use version; our $VERSION = qv('2.3.41');

use List::MoreUtils qw(uniq);
use Params::Validate qw(:all);

use Class::Std::Fast::Storable;
{
  my %id_of               : ATTR(:name<id>);
  my %name_of             : ATTR(:get<name> :set<name>);
  my %gender_of           : ATTR(:get<gender> :set<gender>);   #0 for male, 1 for female
  my %father_of           : ATTR(:get<father> :set<father>);
  my %mother_of           : ATTR(:get<mother> :set<mother>);
  my %children_of         : ATTR(:get<children> :set<children>);  #ARRAYREF of Person
  my %email_of            : ATTR(:get<email> :set<email>);
  my %homepage_of         : ATTR(:get<homepage> :set<homepage>);
  my %date_of_birth_of    : ATTR(:get<date_of_birth> :set<date_of_birth>);
  my %date_of_death_of    : ATTR(:get<date_of_death> :set<date_of_death>);
  my %is_living_of        : ATTR(:get<is_living> :set<is_living>);   #1 for living, 0 for dead
  my %place_of_birth_of   : ATTR(:get<place_of_birth> :set<place_of_birth>);
  my %place_of_death_of   : ATTR(:get<place_of_death> :set<place_of_death>);
  my %cemetery_of         : ATTR(:get<cemetery> :set<cemetery>);  # see Cemetery.pm
  my %schools_of          : ATTR(:get<schools> :set<schools>);     #ARRAYREF of strings
  my %jobs_of             : ATTR(:get<jobs> :set<jobs>);              #ARRAYREF of strings
  my %work_places_of      : ATTR(:get<work_places> :set<work_places>);
  my %places_of_living_of : ATTR(:get<places_of_living> :set<places_of_living>);
  my %general_of          : ATTR(:get<general> :set<general>);
  my %default_picture_of  : ATTR(:get<default_picture> :set<default_picture>);

  sub get_spouses {
  	my ($self) = validate_pos(@_, {type => SCALARREF});
  	return () unless defined $self->get_children();

  	my ($parent_1, $parent_2) = ($self->get_gender() == 0) ?
  		(\%father_of, \%mother_of) : (\%mother_of, \%father_of);

  	my @spouse_set;
    foreach my $child (@{$self->get_children()}) {
      my $child_ident = ident $child;
      push @spouse_set, $parent_2->{$child_ident}
      	if($parent_1->{$child_ident} == $self
      	   && defined $parent_2->{$child_ident});
  	}
  	return uniq @spouse_set;
  }

  sub get_peers {
  	my ( $self ) = validate_pos(@_, {type => SCALARREF});

  	if (defined $self->get_mother() && defined $self->get_mother()->get_children()) {
    return grep { (!defined $_->get_father() && !defined $self->get_father()) ||
                  ($_->get_father() == $self->get_father())}
      @{$self->get_mother()->get_children()};
  	}
  	elsif (defined $self->get_father() && defined $self->get_father()->get_children()) {
    	return grep { !defined $_->get_mother() }
      		@{$self->get_father()->get_children()};
  	}
  	else {
    	return ($self);
  	}
  }

  sub get_soft_peers {
  	my ( $self, $parent_type ) = validate_pos(@_, {type => SCALARREF},
  		{type => SCALAR});

  	my ($parent_func, $other_parent_func) = ($parent_type eq 'mother') ?
  		(\&get_mother, \&get_father) : (\&get_father, \&get_mother);

    if ( defined $parent_func->($self) ) {
      return grep {(!defined $other_parent_func->($_) && defined $other_parent_func->($self)) ||
        (defined $other_parent_func->($_) && !defined $other_parent_func->($self)) ||
        (defined $other_parent_func->($_) && defined $other_parent_func->($self) &&
         $other_parent_func->($_) != $other_parent_func->($self)) }
        @{$parent_func->($self)->get_children()};
    }
    else{
      return ();
    }
  }

  sub brief_info {
  	my ( $self, $textGenerator ) = validate_pos(@_, {type => SCALARREF},
  		{type => HASHREF});

  	my $brief_info = "";
  	$brief_info .= $textGenerator->{father} . ': ' . $self->get_father()->get_name()->get_long_name() . ' '
      if(defined $self->get_father() && defined $self->get_father()->get_name());
    $brief_info .= $textGenerator->{mother} . ': ' . $self->get_mother()->get_name()->get_long_name() . ' '
      if(defined $self->get_mother() && defined $self->get_mother()->get_name());
    $brief_info .= $textGenerator->{date_of_birth} . ': '  .$self->get_date_of_birth()->format() . ' '
      if(defined $self->get_date_of_birth());
	$brief_info .= $textGenerator->{date_of_death} . ': ' . $self->get_date_of_death()->format() . ' '
	  if(defined $self->get_date_of_death());

   return $brief_info;
  }
}

#Static variables for unknown male and female
our $unknown_male = Ftree::Person->new( {id => 'unknown_male'} );
our $unknown_female = Ftree::Person->new( {id => 'unknown_female'} );

$unknown_male->set_gender(0);
$unknown_female->set_gender(1);

$unknown_male->set_mother($unknown_female);
$unknown_male->set_father($unknown_male);
$unknown_female->set_mother($unknown_female);
$unknown_female->set_father($unknown_male);

1;