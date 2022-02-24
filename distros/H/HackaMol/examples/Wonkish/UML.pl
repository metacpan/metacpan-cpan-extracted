use Modern::Perl;
use UML::Class::Simple;
use Data::Dumper;

my @classes = classes_from_files(['lib/HackaMol.pm',glob('lib/HackaMol/*.pm')],'/Role/');
my $painter = UML::Class::Simple->new(\@classes);
$painter->inherited_methods(0);

$painter->as_png('stuff.png');

#print Dumper $painter->as_dom();


