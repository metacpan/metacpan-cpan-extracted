
use strict;
use warnings;

use Test::More tests => 3;

# testing that we can install several different keywords into the same scope
{
    package Monster;

    use Method::Signatures::Simple::ParseKeyword;
    use Method::Signatures::Simple::ParseKeyword name => 'action', invocant => '$monster';
    use Method::Signatures::Simple::ParseKeyword method_keyword => 'constructor', invocant => '$species';
    use Method::Signatures::Simple::ParseKeyword function_keyword => 'function';

    constructor spawn (@args) {
        bless {@args}, $species;
    }

    action speak (@words) {
        return join ' ', $monster->{name}, $monster->{voices}, @words;
    }

    action attack ($me: $you) {
        $you->take_damage($me->{strength});
    }

    method take_damage ($hits) {
        $self->{hitpoints} = calculate_damage($self->{hitpoints}, $hits);
        if($self->{hitpoints} <= 0) {
            $self->{is_dead} = 1;
        }
    }

    function calculate_damage ($hitpoints, $damage) {
        return $hitpoints - $damage;
    }
}

package main;
my $hellhound = Monster->spawn( name => "Hellhound", voices => "barks", strength => 22, hitpoints => 100 );
is $hellhound->speak(qw(arf arf)), 'Hellhound barks arf arf';

my $human = Monster->spawn( name => 'human', voices => 'whispers', strength => 4, hitpoints => 16 );
$hellhound->attack($human);
is $human->{is_dead}, 1;
is $human->{hitpoints}, -6;

__END__

