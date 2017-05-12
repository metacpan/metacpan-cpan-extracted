######################################################################
# Create an array as part of an object
######################################################################

print "1..1\n";

$init = "";
require "t/init.pl";

$js->array_by_path("document.form");

my $source = <<EOT;
$init
document.form[0] = "abc";
EOT

my $rc = $js->eval($source);
die "eval returned undef" unless $rc;
if($js->property_get("navigator.appVersion") ne "3") {
    print "not ";
}

print "ok 1\n";
