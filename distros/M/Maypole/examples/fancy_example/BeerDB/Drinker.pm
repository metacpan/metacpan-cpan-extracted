package BeerDB::Drinker;
use strict;
use warnings;

use Data::Dumper;

__PACKAGE__->columns('Stringify' => qw/handle/);

# A drinker is a person but we do not want to select who that person is 
# from a list because this is a 1:1 relationship rather than a M:1. 
# The no_select option tells AsForm not to bother making a select box

__PACKAGE__->has_a(person => 'BeerDB::Person', no_select => 1);

# Drinker drinks many beers at pubs if they are lucky. I like to specify the
# name of the foreign key unless i can control the order that the
# cdbi classes are created. CDBI does not guess very well the fk column.

#__PACKAGE__->has_many(pints => 'BeerDB::Pint', 'drinker');

# When we create a drinker we want to create a person as well
# So tell AsForm to display the person inputs too.

sub display_columns { qw/person handle/ }
sub list_columns { qw/person handle/ }
# AsForm and templates may check for search_colums when making 
#sub search_columns { qw/person handle/ }

# We need to tweak the cgi inputs a little. 
# Since list is where addnew is, override that.
# Person is a has_a rel and AsForm wont make foreign inputs automatically so
# we manually do it.

sub list : Exported {
	my ($self, $r) = @_;
	$self->SUPER::list($r);
	my %cgi = $self->to_cgi;
	$cgi{person} = $self->to_field('person', 'foreign_inputs');
	$r->template_args->{classmetadata}{cgi} = \%cgi;
	#$r->template_args->{classmetadata}{search_cgi} = $self->search_inputs;
}


	

#sub foreign_input_delimiter { '__IMODDD__'}

1;
