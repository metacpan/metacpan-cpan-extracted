use strict;
use warnings;
use Test::More;
use lib './t';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Getopt::EX::Hashed 'has';

has string    => ( spec => '=s' );
has say       => ( spec => '=s', default => "Hello" );
has number    => ( spec => '=i' );
has thank_you => ( spec => '' );
has for_all   => ( spec => '' );
has the_fish  => ( spec => '' );

@ARGV = qw(
    --string Alice
    --number 42
    --thank_you
    --for-all
    --thefish
    );

use Getopt::Long;
my $app = Getopt::EX::Hashed->new() or die;
if (our $IMPROPER_USE) {
    Getopt::EX::Hashed->configure(REMOVE_UNDERSCORE => 1);
} else {
    $app->configure(REMOVE_UNDERSCORE => 1);
}
GetOptions($app->optspec) or die;


is($app->{string},    "Alice", "String");
is($app->{say},       "Hello", "String (default)");
is($app->{number},         42, "Number");
is($app->{thank_you},       1, "underscore");
is($app->{for_all},         1, "replace underscore");
is($app->{the_fish},        1, "remove underscore");

done_testing;
