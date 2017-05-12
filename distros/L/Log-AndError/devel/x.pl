$one = "%s: LEVEL[%d]: %s";
$two = "%s: LEVEL[%d]:";
$three = "%s%d%s";
$four = "%d%s%s";

print(_template_check($one), "\n");
print(_template_check($two), "\n");
print(_template_check($three), "\n");

sub _template_check {
my $temp = $_[0];
return($temp =~ m/.*\%s.*\%d.*\%s.*/gox);
}

sleep(3);
