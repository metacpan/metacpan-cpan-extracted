
require "../CGIChecker.pm";
require "readfile.inc";

$TEST = "attribs";

print "$TEST\n";

$checker = new HTML::CGIChecker (
	mode => 'allow',
	allowclasses => [qw( images )],
	check_attribs => {
	    img => [qw( src width )]
	}
);

$html = readfile("$TEST.in");
$res = readfile("$TEST.res");

($out, $Errors) = $checker->checkHTML($html);

if ($ARGV[0] eq "out") {
    open(RES, ">$TEST.res");
    $, = "\n";
    print RES @{$Errors};
    close RES;
}


if (join("\n", @{$Errors}) eq $res) {
    print "ok";
}
else {
    print "not ok";
    exit 1;
}
