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

@ARGV = qw(
    --string Alice
    --number 42
    );

use Getopt::Long;
my $app = Getopt::EX::Hashed->new() or die;
GetOptions($app, $app->optspec) or die;

is($app->{string}, "Alice", "String");
is($app->{say}, "Hello", "String (default)");
is($app->{number}, 42, "Number");

done_testing;
