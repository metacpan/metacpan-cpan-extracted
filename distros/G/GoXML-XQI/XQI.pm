package GoXML::XQI;

# (c)1999 XML Global Technologies, Inc.
# All Rights Reserved.
# Author: Matthew MacKenzie <matt@xmlglobal.com>

use strict;
use IO::Handle;
use Socket;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
$VERSION = '1.1.4';

sub new {
	my($class) = shift;
	my($self) = {};
	bless($self,$class);
	$self->_init(@_);
	return($self);
}

sub _init {
	my($self) = shift;
	if (@_) {
		my(%extra) = @_;
		@$self{keys %extra} = values %extra;
	}
}


sub Query {
	my($self) = shift;
	my(%info) = @_;
	
	my($sock) = _socket($self);
	
	my($q) = "<?xml version=\"1.0\"?>\n<GOXML>\n <QUERY>\n";

	croak "You must supply a keyword\n" unless $info{KEYWORD};
	
	$q .= "  <KEYWORD>$info{KEYWORD}</KEYWORD>\n" .
	      "   <TAG>$info{TAG}</TAG>\n" .
	      "   <CATEGORY>$info{CATEGORY}</CATEGORY>\n" .
	      " </QUERY>\n</GOXML>\n";

	if ($self->{VERBOSE}) {
		$self->verbose("Now making Query to $self->{HOST}:$self->{PORT}..\n***$q***");
	}
	print $sock $q;
	
	if ($self->{VERBOSE}) {
		$self->verbose("Request sent, returning filehandle.");
	}
	return($sock);
}

sub Submit {
	my $self = shift;
	my %info = @_;
	my $sock = _socket($self);
        
        my $q = "<?xml version=\"1.0\"?>\n<GOXML>\n <RESOURCE>\n";

	if (!($info{HREF} && $info{DESCRIPTION})) {
		croak "You need to supply the HREF or DESCRIPTION.\n";
	}
	if (!$info{CATEGORY}) {
		$info{CATEGORY} = 8;
	}
	
	$q .= "  <HREF>$info{HREF}</HREF>\n" .
	      "  <DESCRIPTION>$info{DESCRIPTION}</DESCRIPTION>\n" .
              "  <CATEGORY>$info{CATEGORY}</CATEGORY>\n" .
	      " </RESOURCE>\n</GOXML>\n";
	
	if ($self->{VERBOSE}) {
                $self->verbose("Sending Resource..\nDetails:\n$q");
	}

        print $sock $q;
        
        if ($self->{VERBOSE}) {
                $self->verbose("Resource sent, processing answer..");
        }
	my ($resp) = '';

	while (<$sock>) {
		$resp .= $_;
		last if $_ =~ m!</GOXML>!i;
	}

	if ($resp =~ /QUEUED/) {
		if ($self->{VERBOSE}) {
			$self->verbose("Resource addition suceeded.\nDetails:\n$resp");
		}
		return(1);
	}
	else {
		if ($self->{VERBOSE}) {
                        $self->verbose("Resource addition failed.");
			if ($resp =~ m!DUPLICATE!) {
				$self->verbose("\t-The resource submitted has already been indexed or queued.");
                	}
		}	

		return(0);
	}		
}

sub _socket {
	my($self) = shift;
        my($remote) = $self->{HOST} || 'www.goxml.com';
        my($port) = $self->{PORT} || '5910';
        my($iaddr,$paddr,$proto,$line);
        $iaddr = inet_aton($remote) or croak ($!);
        $paddr = sockaddr_in($port, $iaddr) or croak ($!);
        $proto = getprotobyname('tcp') or croak ("$!");
        socket(SOCK, PF_INET, SOCK_STREAM, $proto) or croak ($!);
        connect(SOCK, $paddr) or croak ($!);
        autoflush SOCK 1;
        return(\*SOCK);
}

sub verbose {
	my($self) = shift;
	my($msg) = shift;
	print STDERR $msg,"\n";
}

1;
__END__

=head1 NAME

GoXML::XQI - Perl extension for the XML Query Interface at xqi.goxml.com.

=head1 SYNOPSIS

  use GoXML::XQI;
  $q = new GoXML::XQI(
	HOST => 'www.goxml.com',
	PORT => '5910',
  );
  $fh = $q->Query(
		KEYWORD => $keywd,
		TAG => $tag,
		CATEGORY => $categ);

  while (<$fh>) {
	# Do something with the search results..
  }
	
  $resp = $q->Submit(
		HREF => $url,
		DESCRIPTION => $description,
		CATEGORY => $category);

  print "Succeeded.\n" if $resp;

=head1 DESCRIPTION

This module was designed to allow authorized third parties to connect
to the XML index at www.goxml.com:5910.  While generally a trivial
task, this module will stay up to date and backwards compatible with
newer and older versions of XQI.

Everyone is _authorized_ to use this service, but people who are paying us get
first priority :).


=head1 CATEGORIES

Below is a list of categories currently accepted by Submit():

1 = Arts & Humanities
2 = Health
3 = Business & Economy
4 = News & Media
5 = Computers & Internet
6 = Recreation & Sports
7 = Education
8 = Reference [DEFAULT]
9 = Entertainment
10 = Science
11 = Family
12 = Shopping
13 = Government
14 = Society & Culture
15 = News Groups (XSL-List, ebXML-*, your-list??)

=head1 AUTHOR

C. Matthew MacKenzie <matt@xmlglobal.com>

=head1 SEE ALSO

http://www.goxml.com

=cut

