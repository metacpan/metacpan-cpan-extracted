use Deeme;
use strict;
use Deeme::Backend::SQLite;

use feature 'say';

my $Deeme = Deeme->new(
    backend => Deeme::Backend::SQLite->new( database => "/tmp/deeme.db" ) );

$Deeme->once(
    roar => sub {
        my ( $tiger, $times ) = @_;
        say 'RAWR! , You should see me only once' for 1 .. $times;
    }
);
$Deeme->on(
    roar => sub {
        my ( $tiger, $times ) = @_;
        say 'You can see me for 3 times i guess' for 1 .. $times;
    }
);

say "Events added";

# replace with the actual test
