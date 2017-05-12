######################################################################
# functions2
######################################################################

print "1..1\n";

$init = "";
require "t/init.pl";

$submitted = "0";

my $obj = $js->object_by_path("submitter");
$js->function_set("submit", sub { $submitted = 1 });

my $forms = $js->array_by_path("document.forms");
my $e = $js->array_set_element_as_object($forms, 0, $obj);

my $source = <<EOT;
$init
document.forms[0].submit();
EOT

my $rc = $js->eval($source);

die "eval returned undef" unless $rc;

if(!$submitted) {
    print "not ";
}

print "ok 1\n";

$js->destroy();
