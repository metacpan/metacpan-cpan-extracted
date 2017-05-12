use Deeme;
use strict;
use Deeme::Backend::Mango;

use feature 'say';

my $Deeme = Deeme->new(
    backend => Deeme::Backend::Mango->new(
        database => "deeme",
        host     => "mongodb://localhost:27017",
    )
);


$Deeme->once(roar => sub {
  my ($tiger, $times) = @_;
  say 'RAWR! , You should see me only once' for 1 .. $times;
});
$Deeme->on(roar => sub {
  my ($tiger, $times) = @_;
  say 'You can see me for 3 times i guess' for 1 .. $times;
});

$Deeme->emit(roar => 1);
$Deeme->emit(roar => 1);
$Deeme->emit(roar => 1);


# replace with the actual test
