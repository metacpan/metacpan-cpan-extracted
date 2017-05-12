#!perl -T

use warnings;
use strict;

use Test::More tests => 3;

my $class;
BEGIN {
    $class = 'JavaScript::Framework::jQuery'; 
	use_ok( $class );
}

my $jquery;


$jquery = $class->new(
    library => {
        src => [ 'jquery.min.js' ],
        css => [ { href => 'ui.all.css', media => 'screen' } ],
    },
    plugins => [
        {
            name => 'mcDropdown',
            library => {
                src => [ 'jquery.mcdropdown.js', 'jquery.bgiframe.js' ],
                css => [ { href => 'jquery.mcdropdown.css', media => 'all' } ],
            },
        },
    ],
);
isa_ok($jquery, $class);


# $(document).ready(function () {
#     $(<target_selector>).mcDropdown(<source_url> [, <options> ]);
# });

$jquery->construct_plugin(
    name => 'mcDropdown',
    target_selector => '#input_id',     # usually an HTML INPUT element to provide kbd functionality, but could be any block element.
    source_ul => '#ul_id',              # HTML ID of UL from which new mcDropdown menu is populated.
);

eval {
    $jquery->construct_plugin();
};
ok($@, 'exception for empty argument list');


