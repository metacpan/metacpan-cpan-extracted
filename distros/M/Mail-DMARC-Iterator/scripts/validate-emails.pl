use strict;
use warnings;
use lib 'lib';
use Mail::DMARC::Iterator '$DEBUG';
use Net::DNS;
use Getopt::Long qw(:config posix_default bundling);

sub usage {
    print STDERR <<USAGE;

Verify DMARC status using DKIM signatures and SPF information. The SPF
information can either be given on the command line or extracted from
Received-SPF header inside the mail.

It will scan the given directories and files for mails, supported formats
are multiple mails per file with mbox-format and single mails per file like
in maildir-format. If no files or directories are given it will expect to 
read these names from stdin.

The result will consist of the value (Pass, Fail...) and the reason.
In case of Pass the reason will be the method which caused the Pass first, i.e.
DKIM or SPF

Usage: $0 [options] [dir|mbox]
Options: 
   -h|--help       this help
   -d|--debug      enable debugging

   --spf-from M    email of sender in SMTP dialog
   --spf-srcip S   source IP address of sender
   --spf-helo N    name from helo/ehlo in SMTP dialog
   --spf-received  try to use Received-SPF header in mail
   --spf-sp2dinfo  try to use X-SP2D-INFO header in mail

   --dns-first     if DNS lookups and more data from mail are needed to proceed
                   first do the DNS lookups 

USAGE
    exit(2);
}

*debug = \&Mail::DMARC::Iterator::debug;
my (%spf,$dnsfirst);
GetOptions(
    'spf-from=s'   => \$spf{mailfrom},
    'spf-srcip=s'  => \$spf{ip},
    'spf-helo=s'   => \$spf{helo},
    'spf-received' => \$spf{received},
    'spf-sp2dinfo' => \$spf{sp2dinfo},
    'dnsfirst'     => \$dnsfirst,
    'h|help'       => sub {usage()},
    'd|debug'      => \$DEBUG,
)or usage();

my $res = Net::DNS::Resolver->new;
my %globdns;

my $mbox = Mailbox->new(@ARGV);
my ($dmarc,$id);

mail: 
while ( my $mail = $mbox->nextmail ) {

    $id = $mail->{file};
    $id .= '#'.$mail->{idx} if $mail->{idx};

    my $buf = '';
    my $hdr;
    while (!defined $hdr) {
	my $lbuf = $mbox->nextdata;
	$lbuf eq '' and last;
	$buf .= $lbuf;
	$hdr = substr($buf,0,pos($buf)) if $buf =~m{\n\r?\n}g;
    };

    # X-SP2D-INFO: ...; from=<...>; helo=EHLO:...; ... srcip=...
    my %spf_args = %spf;
    if ($spf_args{sp2dinfo} and $hdr =~m{^X-SP2D-INFO:\s*(.*)}m) {
	# extract info from mail header X-SP2D-INFO
	my $v = $1;
	%spf_args = ();
	$spf_args{mailfrom} = $1 if $v =~s{\bfrom=<([^>]*)>;?}{};
	$spf_args{helo} = $1 if $v =~s{\bhelo=(?:EHLO|HELO):([^\s;]+)}{};
	$spf_args{ip} = lc($1||$2) if $v =~s{\bsrcip=(?:::ffff:([\d\.]+)|([\da-f\.:]+));?}{}i;
    } elsif ($spf_args{received}) {
	# keep given SPF args
	# extract result Received-SPF
	%spf_args = (spf_result => undef);
    } elsif (%spf_args) {
	# keep
    }

    my $subj = $hdr =~m{^Subject:[ \t]*(.*\n(?:[ \t].*\n)*)}mi 
	? $1:'NO SUBJECT';
    $subj =~s{[\r\n]+}{}g;
    print STDERR "\n--- $subj | $id\n";

    $dmarc = Mail::DMARC::Iterator->new(
	%spf_args,
	dnscache => \%globdns,
    );

    my $eof;
    my ($result,@todo) = $dmarc->next($buf);
    while (!$result and @todo) {
	my $todo = shift(@todo); 
	$todo = shift(@todo) if @todo && $dnsfirst && !ref($todo);
	if (!ref($todo)) {
	    $DEBUG && debug("getting more data from mail");
	    # need more data from mail
	    die "eof already reached" if $eof;
	    my $buf = $mbox->nextdata;
	    ($result,@todo) = $dmarc->next($buf);
	    $eof = 1 if $buf eq '';
	} else {
	    # need a DNS lookup
	    $DEBUG && debug("processing DNS query: "
		.($todo->question)[0]->string);
	    my $answer = $res->send($todo);
	    ($result,@todo) = $dmarc->next($answer 
		|| [ $todo, $res->errorstring ]);
	}
    }
    printf STDERR "%s from-domain=%s; reason=%s; action=%s\n", 
	$result||'<undef>', 
	$dmarc->domain || 'unknown',
	$todo[0] || 'unkown',
	$todo[1] || 'no action';
    print "Authentication-Results: hostname;\n ".
	join(";\n ", $dmarc->authentication_results)."\n";
}


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

