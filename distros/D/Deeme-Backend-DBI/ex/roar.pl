use Deeme;
use strict;
use lib './lib';
use Deeme::Backend::DBI;

use feature 'say';

my $Deeme = Deeme->new(
    backend => Deeme::Backend::DBI->new(
        database => "dbi:SQLite:dbname=/var/tmp/deeme.db"
    )
);
$Deeme->on(
    roar => sub {
        my ( $tiger, $times ) = @_;
        say 'You can see me for 3 times i guess' for 1 .. $times;
    }
);
$Deeme->once(
    roar => sub {
        my ( $tiger, $times ) = @_;
        say 'RAWR! , You should see me only once' for 1 .. $times;
    }
);

$Deeme->emit( roar => 1 );
$Deeme->emit( roar => 1 );
$Deeme->emit( roar => 1 );

# replace with the actual test
