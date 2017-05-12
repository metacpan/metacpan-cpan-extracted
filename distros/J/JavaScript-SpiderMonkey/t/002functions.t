######################################################################
# Testcase:     Define Functions and Perl callbacks
# Revision:     $Revision: 1.1.1.1 $
# Last Checkin: $Date: 2006/02/01 06:00:49 $
# By:           $Author: mschilli $
#
# Author: Mike Schilli m@perlmeister.com, 2002
######################################################################

print "1..3\n";

use JavaScript::SpiderMonkey;
my $js = JavaScript::SpiderMonkey->new();
$js->init();

$js->object_by_path("navigator.appName");
$js->object_by_path("document.location");
my $parloc = $js->object_by_path("parent.location");
$js->function_set("replace",
         sub { $buffer .= "URL:$_[0]"; }, $parloc);

    # Function write()
our $buffer;
$js->function_set("write", sub { $buffer .= "f0" . join('', @_) });

    # Method navigator.write()
my $doc = $js->object_by_path("document.location");
$js->function_set("slice", sub { $buffer .= "f1" . join('', @_) }, $doc);

    # Method navigator.appName.write()
$doc = $js->object_by_path("navigator.appName");
$js->function_set("dice", sub { $buffer .= "f2" . join('', @_) }, $doc);

$buffer = "";

my $code = <<EOT;
for(i = 0; i < 2; i++) {
    write("v1 ");
    document.location.slice("v2 ");
    navigator.appName.dice("v3 ");
    parent.location.replace("testurl");
}
EOT

my $rc = $js->eval($code);

# Check return code
print "not " if $rc != 1;
print "ok 1\n";

# print $buffer;
# Check buffer for traces of function/method calls

print "not " unless $buffer eq 
    "f0v1 f1v2 f2v3 URL:testurlf0v1 f1v2 f2v3 URL:testurl";
print "ok 2\n";

$js->destroy();

print "ok 3\n";
