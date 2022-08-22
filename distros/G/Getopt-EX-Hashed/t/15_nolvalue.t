use strict;
use warnings;
use Test::More;
use lib './t';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Getopt::EX::Hashed; {
    Getopt::EX::Hashed->configure(ACCESSOR_LVALUE => 0);
    has say => ( default => 'Hello', is => 'rw' );
}

my $app = Getopt::EX::Hashed->new() or die;

is($app->say, 'Hello', "Getter");

$app->say('Bonjour');
is($app->say, 'Bonjour', "Setter");

eval { $app->say = 'Ciao' };
isnt($@, '', "Wrong Lvalue Setter");

done_testing;
