use 5.010;
use IPIP;

$r=IPIP->new(
    path_info => "../../ipdb/17monipdb.datx",
);
unless($r)
{
	print "init failed\n";
	exit();
}
for (1..10)
{
	$string = int(rand(255)).'.'.int(rand(255)).'.'.int(rand(255)).'.'.int(rand(255));
	$o=$r->find_ex($string);
	say $string.' '.$o;
}
$o=$r->find_ex("255.255.255.255");
say '255.255.255.255 '.$o;