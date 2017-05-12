package inner2;

use if !!eval("&Filter::Unpound::keywords"), "Filter::Unpound" => eval("&Filter::Unpound::keywords");

sub run {
    print "This is the inner2 package\n";
    #debug# print "INNER2: With debugging enabled\n";
}

1;
