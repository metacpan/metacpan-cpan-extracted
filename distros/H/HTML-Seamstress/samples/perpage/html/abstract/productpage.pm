package html::abstract::productpage;

use base qw( html::abstract::common ) ;
sub head { 'Wally World Products' }
sub body { 
  HTML::TreeBuilder->new_from_file('html/products.html')->guts
    }


1;
