use strict;
use warnings;

use Test::More tests => 3;
use JavaScript::Prepare;



my $jsprep = JavaScript::Prepare->new();

{
    my $js = <<JS;
/* I am an empty JavaScript file */
JS
    my $min = $jsprep->process_string( $js );
    ok( $min eq '' )
        or print $min;
}
{
    my $js = <<JS;
// Get the document
var document = window.document;
JS
    my $minified = <<JSMIN;
var document=window.document;
JSMIN
    
    my $min = $jsprep->process_string( $js );
    ok( $min eq $minified )
        or print $min;
}
{
    my $js = <<JS;
/* Example module pattern. */
namespace.module = function () {
    // private variable
    var hidden_string = "Only accessed from within.";
    
    // private method
    var hidden_method = function () {
        console.log("Hidden method activated!");
    }
    
    return {
        public_string = "Accessibile as namespace.module.public_string";
        public_method = function () {
            console.log("Called as namespace.module.public_method()");
            
            // here we can see the "private" vars
            console.log(hidden_string);
            hidden_method();
            
            // scope of "public_method" is also "this"
            console.log(this.public_string);
        }
    }
}(); // parens to execute and return immediately, creating the module
JS
    my $minified = <<JSMIN;
namespace.module=function(){var hidden_string="Only accessed from within.";var hidden_method=function(){console.log("Hidden method activated!");}
return{public_string="Accessibile as namespace.module.public_string";public_method=function(){console.log("Called as namespace.module.public_method()");console.log(hidden_string);hidden_method();console.log(this.public_string);}}}();
JSMIN
    
    my $min = $jsprep->process_string( $js );
    ok( $min eq $minified )
        or print $min;
}
