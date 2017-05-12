use Mail::Cclient qw(set_callback);

set_callback
	log => sub {
	    my ($str, $type) = @_;
	    print "$type: $str\n";
	},
	dlog => sub { print "debug: $_[0]\n" },
	list => sub {
	    shift;
	    print "list: @_\n";
	};

if (@ARGV < 1 || @ARGV > 3) {
    print STDERR "Usage: list.t mailstream [ref [pat]]\n";
    exit 2;
}
my ($stream, $ref, $pat) = @ARGV;
$pat ||= "%";
$c = Mail::Cclient->new($stream) or die "Mail::Cclient->new failed\n";
$c->list($ref, $pat);
