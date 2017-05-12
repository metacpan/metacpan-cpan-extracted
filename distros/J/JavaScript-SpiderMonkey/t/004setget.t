######################################################################
# Testcase:     Set/Get properties of objects
# Revision:     $Revision: 1.1.1.1 $
# Last Checkin: $Date: 2006/02/01 06:00:49 $
# By:           $Author: mschilli $
#
# Author: Mike Schilli m@perlmeister.com, 2002
######################################################################

use warnings;
use strict;

print "1..6\n";

use JavaScript::SpiderMonkey;
my $js = JavaScript::SpiderMonkey->new();
$js->init();

our $buffer = "";

sub getter {
    my(@args) = @_;
    $buffer .= "GETTER: @args\n";
}

sub setter {
    my(@args) = @_;
    $buffer .= "SETTER: @args\n";
}

$js->property_by_path("navigator.appName", "", \&getter, \&setter);

    # Function to write something from JS to a Perl $buffer

my $code = <<EOT;
  navigator.appName      = "Netscape";
  navigator.schnapp      = navigator.appName;
  navigator.appName      = "Netscape2";
  navigator.schnapp      = navigator.appName;
EOT

my $rc = $js->eval($code);

# Check return code
print "not " if $rc != 1;
print "ok 1\n";

# Check output
my $wanted = "SETTER: navigator.appName Netscape\n" .
             "GETTER: navigator.appName Netscape\n" .
             "SETTER: navigator.appName Netscape2\n" .
             "GETTER: navigator.appName Netscape2\n";
if($buffer ne $wanted) {
    print "not ok 2\n";
    print "Expected $wanted but got '$buffer'\n";
} else {
    print "ok 2\n";
}

$js->destroy();

##################################################
# Setter only, no getter
##################################################
$js = JavaScript::SpiderMonkey->new();
$js->init();

$buffer = "";

$js->property_by_path("navigator.appName", "", undef, \&setter);

$rc = $js->eval($code);

# Check return code
print "not " if $rc != 1;
print "ok 3\n";

# Check output
$wanted = "SETTER: navigator.appName Netscape\n" .
          "SETTER: navigator.appName Netscape2\n";

if($buffer ne $wanted) {
    print "not ok 4\n";
    print "Expected $wanted but got '$buffer'\n";
} else {
    print "ok 4\n";
}

$js->destroy();

##################################################
# Getter only, no setter
##################################################
$js = JavaScript::SpiderMonkey->new();
$js->init();

$buffer = "";

$js->property_by_path("navigator.appName", "", \&getter);

$rc = $js->eval($code);

# Check return code
print "not " if $rc != 1;
print "ok 5\n";

# Check output
$wanted = "GETTER: navigator.appName Netscape\n" .
          "GETTER: navigator.appName Netscape2\n";

if($buffer ne $wanted) {
    print "not ok 6\n";
    print "Expected $wanted but got '$buffer'\n";
} else {
    print "ok 6\n";
}

$js->destroy();

