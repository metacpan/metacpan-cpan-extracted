use Mail::Cclient qw(set_callback);

set_callback
	log => sub {
	    my ($str, $type) = @_;
	    print "$type: $str\n";
	},
	dlog => sub { print "debug: $_[0]\n" };

if (@ARGV != 1) {
    print STDERR "Usage: summ.t mailstream\n";
    exit 2;
}
$c = Mail::Cclient->new($ARGV[0]) or die "can't open mailstream $ARGV[0]\n";
$nmsgs = $c->nmsgs;
for ($i = 1; $i <= $nmsgs; $i++) {
    print "$i\n", $c->fetchheader($i, ["Subject"]), $c->fetchtext($i), "---\n";
}
