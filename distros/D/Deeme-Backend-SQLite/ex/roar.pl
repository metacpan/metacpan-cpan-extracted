use Deeme;
use strict;
use Deeme::Backend::SQLite;

use feature 'say';

my $Deeme = Deeme->new(
    backend => Deeme::Backend::SQLite->new(
        database => "/tmp/deeme.db"    )
);


$Deeme->emit(roar=>1);
$Deeme->emit(roar=>1);
$Deeme->emit(roar=>1);
# replace with the actual test
