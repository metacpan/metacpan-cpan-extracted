#!/usr/bin/perl

use strict;

use JavaScript::Squish;

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

print $test_data;


my $djc = JavaScript::Squish->new();

$djc->data($test_data);

print "extract_literal_strings\n";
$djc->extract_literal_strings();
print "[".$djc->data()."]\n";

print "extract_comments\n";
$djc->extract_comments();
print "[".$djc->data()."]\n";

print "extract_strings_and_comments\n";
$djc->extract_strings_and_comments();
print "[".$djc->data()."]\n";

print "remove_comments (keep copyright)\n";
$djc->remove_comments(exceptions => qr/copyright/i);
print "[".$djc->data()."]\n";

print "remove_comments\n";
$djc->remove_comments();
print "[".$djc->data()."]\n";

print "replace_white_space\n";
$djc->replace_white_space();
print "[".$djc->data()."]\n";

print "remove_blank_lines\n";
$djc->remove_blank_lines();
print "[".$djc->data()."]\n";

print "combine_concats\n";
$djc->combine_concats();
print "[".$djc->data()."]\n";

print "join_all\n";
$djc->join_all();
print "[".$djc->data()."]\n";

print "replace_extra_whitespace\n";
$djc->replace_extra_whitespace();
print "[".$djc->data()."]\n";

print "restore_comments\n";
$djc->restore_comments();
print "[".$djc->data()."]\n";

print "restore_literal_strings\n";
$djc->restore_literal_strings();
print "[".$djc->data()."]\n";

print "replace_final_eol\n";
$djc->replace_final_eol();
print "[".$djc->data()."]\n";


print "SQUISH\n";
print "[".JavaScript::Squish->squish($test_data) . "]\n";

#my $eol = $djc->determine_line_ending();

#$djc->extract_comments();
#my $comments = $djc->comments();
#foreach my $c (@{$comments}) {
#    print "############################################################\n";
#    print "# [$c] #\n";
#    print "############################################################\n";
#}

#$djc->extract_strings_and_comments();
#print $djc->data();

#$djc->replace_white_space();
#$djc->remove_blank_lines();
#$djc->combine_concats();
#$djc->join_all();
#$djc->replace_extra_whitespace();

#$djc->restore_comments();
#$djc->remove_comments(exceptions => [ qr/copyright/i ]);
#$djc->remove_comments(exceptions => qr/copyright/i );
#$djc->replace_white_space();
#$djc->remove_blank_lines();
#$djc->restore_literal_strings();
#$djc->replace_final_eol();

#print $djc->data();

