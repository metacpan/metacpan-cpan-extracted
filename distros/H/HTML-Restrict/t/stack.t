use strict;
use warnings;

use Test::More;
use HTML::Restrict ();

my $hr = HTML::Restrict->new;

ok( !@{ $hr->_stripper_stack }, 'stack empty' );

push @{ $hr->_stripper_stack }, 'script', 'style', 'pre', 'script';
$hr->_delete_tag_from_stack('script');
is_deeply(
    $hr->_stripper_stack,
    [ 'script', 'style', 'pre' ],
    'deletes from stack in correct order and amount'
);

done_testing();
