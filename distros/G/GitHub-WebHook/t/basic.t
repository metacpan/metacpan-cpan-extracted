use strict;
use warnings;
use Test::More;

use_ok('GitHub::WebHook');

{ 
    package GitHub::WebHook::Example; # constructor
    use parent 'GitHub::WebHook';
}

my $ex = new_ok('GitHub::WebHook::Example');
my $error;
$ex->call( {}, 0, { error => sub { $error = $_[0] } } );
is $error, "method call not implemented in GitHub::WebHook::Example", "catch missing call";

done_testing;
