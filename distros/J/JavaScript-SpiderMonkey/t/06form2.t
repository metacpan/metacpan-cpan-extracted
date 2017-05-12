######################################################################
# docwrite()
######################################################################

print "1..1\n";

$init = "";
require "t/init.pl";

my $a = $js->array_by_path("document.array");
my $e = $js->array_set_element($a, 0, "gurkenhobel"); 
#print "SetElement returned $e\n";
my $r = $js->array_get_element($a, 0); 
#print "r=$r\n";
#print $js->dump();

my $source = <<EOT;
$init
document.location.href = document.array[0];
EOT

my $rc = $js->eval($source);

die "eval returned undef" unless $rc;

my $val = $js->property_get("document.location.href");

if($val ne "gurkenhobel") {
    print STDERR "Val is '$val'\n";
    print "not ";
}

print "ok 1\n";

$js->destroy();
