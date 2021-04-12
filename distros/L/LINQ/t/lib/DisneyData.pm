use strict;
use warnings;

package DisneyData;

use Exporter::Shiny qw( people pets );
use LINQ qw( LINQ );

{

	package Person;
	use Class::Tiny qw( name id );
}

{

	package Pet;
	use Class::Tiny qw( name id species owner );
}

my @people = (
	Person::->new( name => "Anna",     id => 1 ),
	Person::->new( name => "Elsa",     id => 2 ),
	Person::->new( name => "Kristoff", id => 3 ),
	Person::->new( name => "Sophia",   id => 4 ),
	Person::->new( name => "Rapunzel", id => 5 ),
);

sub people () { LINQ \@people }

my $lottie = Person::->new( name => "Charlotte La Bouff", id => 6 );

my @pets = (
	Pet::->new( name => "Sven",   id => 1, owner => $people[2], species => "Reindeer" ),
	Pet::->new( name => "Pascal", id => 2, owner => $people[4], species => "Chameleon" ),
	Pet::->new( name => "Clover", id => 3, owner => $people[3], species => "Rabbit" ),
	Pet::->new( name => "Robin",  id => 4, owner => $people[3], species => "Robin" ),
	Pet::->new( name => "Mia",    id => 5, owner => $people[3], species => "Bluebird" ),
	Pet::->new( name => "Stella", id => 6, owner => $lottie,    species => "Dog" ),
);

sub pets () { LINQ \@pets }

"What can I say? I like Disney.";
