use Mail::Cclient qw(set_callback);

set_callback
	log => sub {
	    my ($str, $type) = @_;
	    print "$type: $str\n";
	},
	dlog => sub { print "debug: $_[0]\n" };

if (@ARGV < 3) {
    print STDERR "Usage: mime.t mailstream msgno section ...\n";
    exit 2;
}
my $stream = shift;
my $msgno = shift;
$c = Mail::Cclient->new($stream) or die "can't open mailstream $stream\n";
while ($section = shift) {
    print "*** $section ***\n", $c->fetchbody($msgno, $section);
}
