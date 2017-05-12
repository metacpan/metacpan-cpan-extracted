######################################################################
# docwrite()
######################################################################

print "1..1\n";

$init = "";
require "t/init.pl";

my $source = <<EOT;
$init
function FormSubmit () {
    document.location.href = "submitted!";
}
function Form() {
    this.submit = FormSubmit;
}

document.form[0] = new Form;
document.form[0].submit();
EOT

my $rc = $js->eval($source);
die "eval returned undef" unless $rc;
if($js->property_get("document.location.href") ne "submitted!") {
    print "not ";
}

print "ok 1\n";

$js->destroy();
