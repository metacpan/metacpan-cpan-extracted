use Mail::Cclient qw(set_callback);

set_callback
	log => sub {
	    my ($str, $type) = @_;
	    print "$type: $str\n";
	},
	dlog => sub { print "debug: $_[0]\n" };

if (@ARGV != 3) {
    print STDERR "Usage: copy.t mailstream msgno destmailbox\n";
    exit 2;
}
my ($stream, $msgno, $dest) = @ARGV;
$c = Mail::Cclient->new($stream) or die "can't open mailstream $stream\n";
$c->copy($msgno, $dest) or die "copy failed\n";
