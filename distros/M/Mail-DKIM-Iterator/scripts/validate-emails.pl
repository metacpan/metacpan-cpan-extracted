use strict;
use warnings;
use lib 'lib';
use Mail::DKIM::Iterator;
use Net::DNS;
use Getopt::Long qw(:config posix_default bundling);

sub usage {
    print STDERR <<USAGE;

Validates DKIM signatures in e-mails.
It will scan the given directories and files for mails, supported formats
are multiple mails per file with mbox-format and single mails per file like
in maildir-format. If no files or directories are given it will expect to 
read these names from stdin.

Usage: $0 [options] [dir|mbox]
Options: 
   -h|--help: this help

USAGE
    exit(2);
}

GetOptions(
    'h|help' => sub {usage()},
);

my $res = Net::DNS::Resolver->new;

# fill with test entry which is used in sign.pl
my %globdns = (
    's._domainkey.example.local' => 'v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDOD/2mm2FfRCkBhtQkE3Wl2M3A9E8PJiSkvciLrSoTePnHC0MSLaNXYUmFHT//zT4ZebruQDgPVsLRLVmWssVaKn9EpKQcd55qVKApFNZSoev5sdzXP9g+AuZYtnkSHzlilqiSttHkadXSAyJ8WOlMC0kTPWEkL+FyWDyezKuj9QIDAQAB'
);

my $mbox = Mailbox->new(@ARGV);
my ($dkim,$id);

mail: 
while ( my $mail = $mbox->nextmail ) {

    $id = $mail->{file};
    $id .= '#'.$mail->{idx} if $mail->{idx};

    my $buf = $mbox->nextdata;
    $buf eq '' and next;
    my $subj = $buf =~m{^Subject:[ \t]*(.*\n(?:[ \t].*\n)*)}mi 
	? $1:'NO SUBJECT';
    $subj =~s{[\r\n]+}{}g;
    print STDERR "\n--- $subj | $id\n";

    $dkim = Mail::DKIM::Iterator->new(dns => \%globdns);

    my $rv;
    my @todo = \'';
    while (@todo) {
	my $todo = shift(@todo);
	if (ref($todo)) {
	    # need more data from mail
	    $buf //= $mbox->nextdata // die "no more data from mail";
	    ($rv,@todo) = $dkim->next($buf);
	    $buf = undef;
	} else {
	    # need a DNS lookup
	    if (my $q = $res->query($todo,'TXT')) {
		# successful lookup
		($rv,@todo) = $dkim->next({
		    $todo => [
			map { $_->type eq 'TXT' ? (join('',$_->txtdata)) : () }
			$q->answer
		    ]
		});
	    } else {
		# failed lookup
		($rv,@todo) = $dkim->next({ $todo => undef });
	    }
	}
    }

    for(@$rv) {
	my $status = $_->status;
	my $domain = $_->domain;
	if (!defined $status) {
	    print STDERR " unkown $domain\n";
	} else {
	    my $error = $_->error;
	    my $warn = $_->warning;
	    print STDERR " $status $domain"
		. ( $error ? " error=\"$error\"":"")
		. ( $warn ? " warning=\"$warn\"":"")."\n";
	}
    }
}

#warn Dumper(\%globdns); use Data::Dumper;

package Mailbox;
sub new {
    my ($class,@files) = @_;

    my $nextfile = do {
	my $getfname = !@files && sub { 
	    defined(my $l = <STDIN>) or return;
	    chomp($l);
	    $l;
	};
	sub {
	    while (1) {
		my $file = shift(@files) || $getfname && &$getfname || last;
		return $file if -f $file && -r _ && -s _;
		unshift @files, glob("$file/*") if -d $file; 
	    }
	    return;
	}
    };

    my $spool1st = qr{^[A-Z]{2,} };
    my $mbox1st = qr{
	From[ ](\S+)[ ]+
	(Mon|Tue|Wed|Thu|Fri|Sat|Sun)[ ]
	(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[ ]+
	(\d{1,2})[ ]
	(\d\d):(\d\d):(\d\d)[ ](\d\d\d\d)
	(?:[ ][+-]?\w+)?
	[ ]*\r?\n
    }x;


    my ($fh,$file,$buf,$mbox,@fwd);
    my $nextbuf = sub {
	begin:

	# something to forward already?
	return shift(@fwd) if @fwd;

	# open file unless we have one open
	while (!$fh) {
	    $file = &$nextfile or return;
	    if ($file eq '-') {
		$fh = \*STDIN
	    } else {
		open($fh,'<',$file) or warn "open $file: $!";
	    }
	    read($fh,$buf,16384);
	    $mbox = $buf =~s{\A$mbox1st}{} ? 1:undef;
	    while (!$mbox && $buf =~m{\A$spool1st}) {
		# strip SMTP envelope
		if ($buf =~m{^DATA\r?\n}mg) {
		    substr($buf,0,pos($buf),'');
		    last;
		}
		read($fh,$buf,16384,length($buf));
	    }
	    push @fwd, {
		file => $file,
		$mbox ? ( idx => $mbox ):()
	    };
	    goto begin;
	}

	# forward data of mail if possible
	if (!$mbox) {
	    push @fwd,$buf if $buf ne '';
	    $buf = '';
	} elsif ($buf =~m{^$mbox1st}mg) {
	    push @fwd,substr($buf,0,$-[0]) if $-[0];
	    $buf = substr($buf,$+[0]);
	    push @fwd,'';
	    push @fwd, {
		file => $file,
		idx  => ++$mbox
	    };
	} else {
	    push @fwd,substr($buf,0,length($buf)-1024,'') 
		if length($buf)>1024;
	}

	# read more data into buffer
	if (! @fwd && !read($fh,$buf,16384,length($buf))) {
	    $fh = undef;
	    push @fwd,$buf if $buf ne '';
	    push @fwd,''; # end of data
	    $buf = '';
	}

	goto begin;
    };

    my $nextmail = sub {
	while ($mbox) {
	    defined(my $buf = &$nextbuf) or return;
	    return $buf if ref($buf);
	}

	# not an mbox
	# skip everything buffered until we have some new file
	while (@fwd) {
	    my $buf = shift(@fwd);
	    return $buf if ref($buf);
	}
	$fh = $file = $buf = undef; # close everything
	return &$nextbuf;
    };

    my $nextdata = sub {
	my $buf = &$nextbuf;
	return $buf if !ref($buf);
	unshift @fwd,$buf;
	return '';
    };

    my $self = bless {
	nextdata => $nextdata,
	nextmail => $nextmail,
    },$class;
}

sub nextmail { shift->{nextmail}() }
sub nextdata { shift->{nextdata}() }

