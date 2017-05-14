#!/usr/local/bin/perl
#
# Copyright (c) 1998 Ugen Antsilevitch (ugen@freebsd.org)
# This software can be used anywhere anytime freely.
# This copyright has to be attached to any software or product that
# uses this code.
#
# API includes: 
# new( ImapHost => imap.host.com , Username => <john> , Password => <secret> , 
#               [Verbose => 1 , Dump => 1 ]);
# connetc();
# logon();
# <total messages in folder> = select(<foldername>);
# @<message numbers> = search(<IMAP Search String, RFC2060>);
# copy(<to foldername>, @<message numbers>);
# del(@<message numbers>);
#
# All functions return true on success and false (undefined) on failure except
# where otherwise noted.
#


1;

package IMAPGet;
require 5.002;
use strict;
use Socket;
use FileHandle;
use Fcntl;

my $TIMEOUT = 300; # 300 seconds should be plenty even for big FETCH
my $IMAP_PORT = 143; # Well..You better know that.
my $IMAP_MAILBOX = 'Inbox';

sub _getsock {
   my $sock = shift;
   my $timeout = shift;
   my ($rin, $ein, $rout, $eout);
   my $resstr = "";
   my $lastchar = "";

   unless (defined $sock) {
	print "IMAPGet: not connected\n";
	return undef;
   }
   
   if ($_ = <$sock>) {
	$resstr = $_;
   	$lastchar = substr($resstr, -1, 1);
   	return $resstr if $lastchar eq "\n";
   }


   while ($lastchar ne "\n") {
        $rin = $ein = "";
        vec($rin, fileno($sock), 1) = 1;
        vec($ein, fileno($sock), 1) = 1;
     
        $timeout = $TIMEOUT if not defined $timeout;
        return undef if (not select($rout=$rin, undef, $eout=$ein, $timeout));

   	$resstr = $resstr . <$sock>;
   	$lastchar = substr($resstr, -1, 1);
   }

   return $resstr;
}


sub new {
my $type = shift;
my %params = @_; 
my $self = {};
$self->{ImapHost} = $params{ImapHost};
$self->{ImapPort} = ($params{ImapPort} or $IMAP_PORT);
$self->{Username} = $params{Username};
$self->{Password} = $params{Password};
$self->{Verbose} = ($params{Verbose} or 0);
$self->{Dump} = ($params{Dump} or 0);
$self->{Opid} = "ZZTOP00";
$self->{Opres} = "OK";

print "! created new instance for IMAP host $self->{ImapHost}\n" if $self->{Verbose};

return bless $self, $type;
}

sub connect {
my $self = shift;
my $imap_addr;
my $imap_iaddr;
my $proto;

if ($self->{ImapHost} =~ /\d+\.\d+\.\d+\.\d+/) {
	$imap_addr = inet_aton($self->{ImapHost});
	if (not $imap_addr) {
		print "IMAPGet: Bad IP address $self->{ImapHost}\n";
		return undef;
	}
} else {
	$imap_addr = gethostbyname($self->{ImapHost});
	if (not $imap_addr) {
		print "IMAPGet: Can't find IMAP host $self->{ImapHost}\n";
		return undef;
	}
}

$imap_iaddr = sockaddr_in($self->{ImapPort}, $imap_addr);
$proto = getprotobyname('tcp');

$self->{Socket} = new FileHandle;
unless (socket($self->{Socket}, PF_INET, SOCK_STREAM, $proto)) {
	print "IMAPGet: Can't create socket\n";
	return undef;
}

unless (connect($self->{Socket}, $imap_iaddr)) {
	print "IMAPGet: Can't connect to port $self->{ImapPort} of IMAP host $self->{ImapHost}\n"; 
	return undef;
}
($self->{Socket})->autoflush();
fcntl($self->{Socket}, F_SETFL, O_NDELAY);

return 1;
} #Connect

sub logon {
my $self = shift;
my $line;
my $sock = $self->{Socket};
unless (defined $sock) {
	print "IMAPGet: not connected\n";
	return undef;
}

$self->{Opres} = "TIMEOUT";
while ($line = _getsock($sock, 30)) {
	print "< $line" if $self->{Dump};
	last if $line =~/\*\s(\w+)\s/ and $self->{Opres}=$1;
}
unless ($self->{Opres} eq "OK") {
	print "IMAPGet: bad greeting\n";
	return undef;
}

print $sock "$self->{Opid} LOGIN $self->{Username} $self->{Password}\n";
print "> $self->{Opid} LOGIN $self->{Username} XXXXXXXXXX\n" if $self->{Dump};

$self->{Opres} = "TIMEOUT";
while ($line = _getsock($sock)) {
	print "< $line" if $self->{Dump};
	last if $line =~/$self->{Opid}\s(\w+)\s/ and $self->{Opres}=$1;
}
$self->{Opid}++;
unless ($self->{Opres} eq "OK") {
	print "IMAPGet: Bad login\n";
	return undef;
}

return 1;
} #Logon

sub select {
my $self = shift;
my $folder = shift;
my $sock = $self->{Socket};
my $line;
unless (defined $sock) {
	print "IMAPGet: not connected\n";
	return undef;
}

my $msgnum;
print $sock "$self->{Opid} SELECT $folder\n";
print "> $self->{Opid} SELECT $folder\n" if $self->{Dump};

$self->{Opres} = "TIMEOUT";
while ($line = _getsock($sock, 600)) {
		print "< $line" if $self->{Dump};
		if ($line =~ /$self->{Opid}\s(\w+)\s/) {
			$self->{Opres} = $1;
			last;
		}

		if ($line =~ /\*\s(\d+)\sEXIST/) {
			$msgnum = $1;
			print "! $msgnum messages in folder $folder\n" if $self->{Verbose};
		}
}
$self->{Opid}++;

unless ($self->{Opres} eq "OK") {
	print "IMAPGet: bad folder $folder\n";
	return undef;
}
print "! Selected $folder OK\n" if $self->{Opres} eq "OK" and $self->{Verbose};
$self->{Folder} = $folder;

return $msgnum;

} #select

sub search {
my $self = shift;
my $searchstr = shift;
my $sock = $self->{Socket};
my $line;
my @smsgs;
my $nsmsgs;
unless (defined $sock) {
	print "IMAPGet: not connected\n";
	return undef;
}

print $sock "$self->{Opid} SEARCH $searchstr\n";
print "> $self->{Opid} SEARCH $searchstr\n" if $self->{Dump};

$self->{Opres} = "TIMEOUT";
while ($line = _getsock($sock, 600)) {
		print "< $line" if $self->{Dump};

		if ($line =~ /\*\sSEARCH(.*)/) {
			@smsgs = split /\s+/, $1;
			shift @smsgs if $smsgs[0] eq "";
			$nsmsgs = @smsgs;
			print "! matched $nsmsgs messages in folder $self->{Folder}\n" if $self->{Verbose};
		}

		if ($line =~ /$self->{Opid}\s(\w+)\s/) {
			$self->{Opres} = $1;
			last;
		}

}
$self->{Opid}++;

unless ($self->{Opres} eq "OK") {
	print "IMAPGet: search failed for folder $self->{Folder}\n";
	return undef;
}
print "! Search in folder $self->{Folder} OK\n" if $self->{Opres} eq "OK" and $self->{Verbose};

return @smsgs;
}


sub fetch {
my $self = shift;
my @smsgs = @_;
my $strsmsgs; 
my $sock = $self->{Socket};
my $line;
my $hline;
my $header = undef;
my $size = 0;
my $curmsg = 0;
my $skip = undef;
my $attr = undef;
my %msgs;
my %msg;
my $tmp;
unless (defined $sock) {
	print "IMAPGet: not connected\n";
	return undef;
}

$strsmsgs = shift @smsgs;
while ($tmp = shift @smsgs) {
	$strsmsgs = $strsmsgs . "," . $tmp;
}


print $sock "$self->{Opid} FETCH $strsmsgs BODY[]\n";
print "> $self->{Opid} FETCH $strsmsgs BODY[]\n" if $self->{Dump};

$self->{Opres} = "TIMEOUT";

while ($line = _getsock($sock)) {
	print "< $line" if $self->{Dump};

	if ($line =~ /$self->{Opid}\s(\w+)\s/ and $size eq 0) {
		$self->{Opres} = $1;
		last;
	}
	if ($line =~ /\*\s(\d+)\sFETCH.*\{(\d+)\}/ 
					and $size eq 0) {
		$curmsg = $1;
		$size = $2; 
		$header = 1;
		$skip = undef;
		$attr = undef;
		%msg = ();
		$msg{Body} = "";
		print "! Getting message number $curmsg\n" 
						if $self->{Verbose};
		next;
	}
	if ($line =~ /^\)/ and $size eq 0) {
		$msgs{$curmsg} = {%msg};
		print "! Finished message number $curmsg\n" 
						if $self->{Verbose};
		next;
	}

	if ($skip) {
		$size -= length $line;
		next;
	}

	if ($header) {
		chomp($hline = $line);
		if ($hline =~ /^\s+(\S+)/) { #Continued attribute
			if ($attr) {
				$msg{$attr} = $msg{$attr} . " " . $1;
			} else {
				print "IMAPGet: bad header in message $curmsg, skipping (1)\n";
				$skip = 1;
			}
		} elsif ($hline =~ /^(.*): (.*)/) { #New attribute
			$attr = $1;
			$msg{$attr} = $2;	
		} elsif ($hline eq "\r") { #Header caput
			$header = undef;
		} else {
			print "IMAPGet: bad header in message $curmsg, skipping (2)\n";
			$skip = 1;
		}
	} else {
		$msg{Body} = $msg{Body} . $line;
	}
	$size -= length $line;

}

$self->{Opid}++;

unless ($self->{Opres} eq "OK") {
	print "IMAPGet: fetch failed for folder $self->{Folder}\n";
	return undef;
}

return %msgs;
} #fetch

sub copy {
my $self = shift;
my $to = shift;
my @smsgs = @_;
my $strsmsgs; 
my $sock = $self->{Socket};
my $line;
my $tmp;
unless (defined $sock) {
	print "IMAPGet: not connected\n";
	return undef;
}

$strsmsgs = shift @smsgs;
while ($tmp = shift @smsgs) {
	$strsmsgs = $strsmsgs . "," . $tmp;
}


print $sock "$self->{Opid} COPY $strsmsgs $to\n";
print "> $self->{Opid} COPY $strsmsgs $to\n" if $self->{Dump};

$self->{Opres} = "TIMEOUT";

while ($line = _getsock($sock)) {
	print "< $line" if $self->{Dump};

	if ($line =~ /$self->{Opid}\s(\w+)\s/) {
		$self->{Opres} = $1;
		last;
	}
}
$self->{Opid}++;

unless ($self->{Opres} eq "OK") {
	print "IMAPGet: copy failed from folder $self->{Folder} to folder $to\n";
	return undef;
}

return 1;
}

sub del {
my $self = shift;
my @smsgs = @_;
my $strsmsgs; 
my $sock = $self->{Socket};
my $line;
my $tmp;
unless (defined $sock) {
	print "IMAPGet: not connected\n";
	return undef;
}

$strsmsgs = shift @smsgs;
while ($tmp = shift @smsgs) {
	$strsmsgs = $strsmsgs . "," . $tmp;
}


print $sock "$self->{Opid} STORE $strsmsgs +FLAGS.SILENT \\Deleted\n";
print "> $self->{Opid} STORE $strsmsgs \n +FLAGS.SILENT \\Deleted\n" if $self->{Dump};

$self->{Opres} = "TIMEOUT";

while ($line = _getsock($sock)) {
	print "< $line" if $self->{Dump};

	if ($line =~ /$self->{Opid}\s(\w+)\s/) {
		$self->{Opres} = $1;
		last;
	}
}
$self->{Opid}++;

unless ($self->{Opres} eq "OK") {
	print "IMAPGet: delete marking failed for folder $self->{Folder}\n";
	return undef;
}

print $sock "$self->{Opid} EXPUNGE\n";
print "> $self->{Opid} EXPUNGE\n" if $self->{Dump};

$self->{Opres} = "TIMEOUT";

while ($line = _getsock($sock)) {
	print "< $line" if $self->{Dump};

	if ($line =~ /$self->{Opid}\s(\w+)\s/) {
		$self->{Opres} = $1;
		last;
	}
}
$self->{Opid}++;

unless ($self->{Opres} eq "OK") {
	print "IMAPGet: expunge failed for folder $self->{Folder}\n";
	return undef;
}


return 1;
}


__END__



