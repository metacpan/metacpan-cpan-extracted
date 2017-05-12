# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 002.t'

#########################

use Test;

plan tests => 2;

use JavaScript::Squish;
ok(1); # If we made it this far, we're ok.

my $test_data = <<JAVASCRIPT;
/********************************
 * come copyright notice        *
 * laskfjslfjs ak fsakljfs kdf  *
 ********************************/

/* some single line comment */

    // another single comment

    var comment_in_string1 = "blah /* hehe */ //haha ";
    var comment_in_string2 = 'blah /* hehe */ //haha ';

    var test = "multi-line 
    text field";
    var test = "asfd asfd"; // comment 3

var x = "blah" + 'asdf' + tset + 'xx'+

'asdf';

    var foo = 'bar'; /* embeded comment */ var test = "xxx";
    var foo = 'bar';/*make sure this doesn't copy off surrounding chars*/var test = "xxx";

    var t = 'x';/*embeded multi line
    comment*/var asdf = 'qwer';

alert("this"+"is"+'some'+'more'+'text');

function blah (asdf) {
    while (x = el[ e++ ]) {
        y++;
    }
};
var x;   
// preceding line has ends in extra spaces up to
// here ^
var test_no_line_ending1 = "blah1"
var test_no_line_ending2 = "blah2"
if (x) { blah(); }
var x = "asdf";

// these should be treated as division
var x = 10 // see if this works
    / 2;
var x = 10 /* see if this works */ / 2;

// this should retain 4 spaces
var x = t.split(/    /);
// this should retain the newlines
var x = t.split(/ b l
 a h /);

JAVASCRIPT

my $test_output = qq|var comment_in_string1=\"blah /* hehe */ //haha \";var comment_in_string2='blah /* hehe */ //haha ';var test=\"multi-line 
    text field\";var test=\"asfd asfd\";var x=\"blah\"+'asdf'+tset+'xxasdf';var foo='bar';var test=\"xxx\";var foo='bar';var test=\"xxx\";var t='x';var asdf='qwer';alert(\"thisis\"+'somemoretext');function blah(asdf){while(x=el[e++]){y++;}};var x;var test_no_line_ending1=\"blah1\"
var test_no_line_ending2=\"blah2\"
if(x){blah();}var x=\"asdf\";var x=10/2;var x=10/2;var x=t.split(/    /);var x=t.split(/ b l
 a h /);
|;

my $c = JavaScript::Squish->squish($test_data);
ok( $c, $test_output, "overall final result test" );


