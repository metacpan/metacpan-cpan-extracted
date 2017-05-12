# This script is a valid TAP script, but an ugly one.
#
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Data::Dumper;
BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Inline::Ruby qw(rb_eval);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

rb_eval <<EOF;
def add(a, b)
    a + b
end
puts "ok 2"
EOF

print "ok ", rb_eval("add(1, 2)"), "\n";
print rb_eval('"this is a string"'), "\n";
print rb_eval('$0'), "\n";
