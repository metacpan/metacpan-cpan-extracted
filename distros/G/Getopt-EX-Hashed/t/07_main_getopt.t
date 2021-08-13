use strict;
use warnings;
use Test::More;
use lib './t';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Getopt::EX::Hashed 'has';

has string   => ( spec => '=s' );
has say      => ( spec => '=s', default => "Hello" );
has number   => ( spec => '=i' );
has so_long  => ( spec => '' );

@ARGV = qw(
    --string Alice
    --number 42
    --so-long
    );

use Getopt::Long;
my $app = Getopt::EX::Hashed->new() or die;
$app->getopt or die;

is($app->{string}, "Alice", "String");
is($app->{say}, "Hello", "String (default)");
is($app->{number}, 42, "Number");
is($app->{so_long}, 1, "dash option");

done_testing;
