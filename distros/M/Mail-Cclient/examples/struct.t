use Mail::Cclient qw(set_callback);

set_callback
	log => sub {
	    my ($str, $type) = @_;
	    print "$type: $str\n";
	},
	dlog => sub { print "debug: $_[0]\n" };

sub addr {
    my $alist = shift;
    return join(", ", map { sprintf('%s@%s (%s)',
				    $_->mailbox, $_->host, $_->personal)
		      } @$alist);
}

if (@ARGV != 2) {
    print STDERR "Usage: struct.t mailstream msgno\n";
    exit 2;
}
my $stream = shift;
my $msgno = shift;
$c = Mail::Cclient->new($stream) or die "can't open mailstream $stream\n";
($env, $body) = $c->fetchstructure($msgno);
printf "from %s\n", addr($env->from),
printf "to %s\n", addr($env->to);
printf "subject is %s\n", $env->subject;

my $type = $body->type;
printf "MIME type %s/%s\n", lc($type), lc($body->subtype);
if ($type eq "MULTIPART") {
    my $part;
    foreach $part (@{$body->nested}) {
	printf "type of subpart: %s/%s\n", lc($part->type), lc($part->subtype);
    }
}
