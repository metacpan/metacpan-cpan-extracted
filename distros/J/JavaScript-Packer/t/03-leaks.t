#!perl

use strict;
use warnings;

use Test::More;
use JavaScript::Packer; 

if (! eval "use Test::Memory::Cycle; 1;" ) {
	plan skip_all => 'Test::Memory::Cycle required for this test';
}

my $packer = JavaScript::Packer->init;
memory_cycle_ok( $packer );

my $js = '
$(document).ready(function(e) {
try {
//  $("body select").msDropDown();
$("#payin").msDropdown({visibleRows:3,rowHeight:30});
$("#payout").msDropdown({visibleRows:8,rowHeight:30});
$("#lang").msDropdown({visibleRows:2,rowHeight:16});

} catch(e) {
	alert(e.message);
}
});
';

for ( 1 .. 5 ) { 
	ok( $packer->minify( \$js,{} ),'minify' );
}

memory_cycle_ok( $packer );
done_testing();
