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
	},
	login => sub {
	    my ($username, $password);
	    local($|) = 1;
	    print "Username: ";
	    chomp($username = <STDIN>);
	    print "Password: ";
	    chomp($password = <STDIN>);
	    return ($username, $password);
	};

$c = Mail::Cclient->new('{localhost/imap}INBOX')
	or die "Mail::Cclient->new failed\n";
$c->list("", "%");
