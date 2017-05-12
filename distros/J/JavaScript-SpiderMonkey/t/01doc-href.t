######################################################################
# Set and retrieve document.location.href
######################################################################

print "1..1\n";

$init = "";

require "t/init.pl";

my $source = <<EOT;
$init
document.location.href = "http://www.com";
EOT

my $rc = $js->eval($source);

die "eval returned undef" unless $rc;

if($js->property_get("document.location.href") ne "http://www.com") {
    print "not ";
}

print "ok 1\n";
