package HTTP::Browscap;

=head1 NAME

HTTP::Browscap - Provides info on web browser capabilities

=head1 SYNOPSIS

 use HTTP::Browscap;
 my $browser = new HTTP::Browscap;

 print $browser->property( { browser  => 'Mozilla/4.03 (Win16; I)',
			     property => 'tables' } );

=head1 DESCRIPTION

This module provides information on a web browsers capabilities 
(eg - table support, frame support), the browser being identified by
its "User Agent" string. This will use the existing Microsoft 
browscap.ini database, a version of which is freely downloadable 
and actively maintained at http://www.browserhawk.com/browscap/

=cut

use strict;
use vars qw($VERSION);
$VERSION = "0.01";  # 23rd May 2000


sub new {
    my $class = shift;
    my $self = bless {}, $class;

    # load in the data
    my $BROWSCAPFILE = '/home/james/lib/perl/HTTP/browscap.ini';
    open (BROWSCAP, $BROWSCAPFILE) or die "Can't open Browscap data file";

    # Build up browser capabilities hash
    my (%browser, $browsername, $browsersubname, %browsersplit);
    while (<BROWSCAP>) {
	next unless ($_);  # skip empty lines 
	next if /^;/;      # skip comments

	if (/^\[(.*)\]$/) { 
	    my $browserstring = $1;
	    if (index($browserstring,'*') == -1) {
		# no wildcards in browsername
		$browsername = $1; # Store browser id for hash key
		$browsersubname = undef;
	    }
	    else {
		$browserstring =~ /^(.*)\*(.*)$/;
		$browsername = $1;
		$browsersubname = $2;
	    }	    
	}
	elsif ($browsername && /^([^=]+)=(.+)$/) {
	    # add capabilities under each browsername hash key
	    if (defined($browsersubname)) {
		# wildcards
		$browsersplit{$browsername}{$browsersubname}{$1} = $2;
	    } else { 
		$browser{$browsername}{$1} = $2; 
	    }
	}
    }
    close (BROWSCAP);

    $self->{_browser} = \%browser;
    $self->{_browsersplit} = \%browsersplit;

    $self;
}

sub setbrowser {
    my $self = shift;
    my $userbrowser = shift;

    # Wipe if no User Agent given
    unless ($userbrowser) {
	delete $self->{userbrowser};
	return;
    }

    $self->{userbrowser} = $userbrowser;
}




sub property {
    my $self = shift;
    my $param = shift;

    my $browsername = $param->{browser} || $self->{userbrowser};
    my $propertyname = $param->{property};

    (defined($browsername) && defined($propertyname)) or return undef;

    # exact match exists?
    no strict 'refs';
    if (exists($self->{_browser}->{$browsername})) {
	if (exists($self->{_browser}->{$browsername}->{$propertyname})) {
	    # return if exact match
	    return $self->{_browser}->{$browsername}->{$propertyname};
	}
	elsif (exists($self->{_browser}->{$self->{_browser}->{$browsername}->{parent}}->{$propertyname})) {
	    # return if exact match in parent
	    return $self->{_browser}->{$self->{_browser}->{$browsername}->{parent}}->{$propertyname};
	}
    }
    use strict 'refs';

    # no exact match, do fuzzy matching

    foreach my $frontmatch (keys %{$self->{_browsersplit}}) {
	if (index($browsername, $frontmatch) == 0) {  # front matches
	    my $restofmatch = substr($browsername, length($frontmatch));
	    foreach my $backmatch (keys %{$self->{_browsersplit}->{$frontmatch}}) {
		if ($restofmatch =~ /^.*${backmatch}$/) { 
		if (exists($self->{_browsersplit}->{$frontmatch}->{$backmatch}->{$propertyname})) {
		    return %{$self->{_browsersplit}->{$frontmatch}->{$backmatch}->{$propertyname}};
		}
		elsif (exists($self->{_browser}->{$self->{_browsersplit}->{$frontmatch}->{$backmatch}->{parent}}->{$propertyname})) {
		    return $self->{_browser}->{$self->{_browsersplit}->{$frontmatch}->{$backmatch}->{parent}}->{$propertyname};
		}
	    }
	}
    }
}
return undef;
}


1;


