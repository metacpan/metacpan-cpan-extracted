package LyricFinder::_Class;

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use HTML::Strip;
use Carp;

our $AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:112.0) Gecko/20100101 Firefox/112.0";
our $DEBUG = 0; # If you want debug messages, set debug to a true value, and
				# messages will be output with warn.

sub new
{
	my $class = shift;
	my $source = shift;

	my $self = {};

	$self->{'-debug'}  = $DEBUG;
	$self->{'-agent'}  = $AGENT;
	$self->{'-cache'}  = '';
	$self->{'Error'}   = 'Ok';
	$self->{'Source'}  = $source;
	$self->{'Site'}    = '';
	$self->{'Order'}   = '';
	$self->{'Tried'}   = '';
	$self->{'Url'}     = '';
	$self->{'image_url'} = '';
	$self->{'Credits'} = [];

	#EXTRACT ANY ARGUMENTS:
	while (@_) {
		if ($_[0] =~ /^\-/o) {
			my $key = shift;
			$self->{$key} = (!defined($_[0]) || $_[0] =~/^\-/) ? 1 : shift;
			next;
		}
		shift;
	}	

	#NOW EXTRACT ANY SUBMODULE-SPECIFIC HASH ARGUMENTS (ie. "-Submodule => {args}"):
	if (defined($self->{"-$source"}) && ref($self->{"-$source"}) =~ /HASH/) {
		my @subarglist = %{$self->{"-$source"}};
		while (@subarglist) {
			if ($subarglist[0] =~ /^\-/o) {
				my $key = shift @subarglist;
				$self->{$key} = (!defined($subarglist[0]) || $subarglist[0] =~/^\-/) ? 1 : shift(@subarglist);
				next;
			}
			shift @subarglist;
		}
	}

	$self->{'-debug'} = $DEBUG  unless (defined($self->{'-debug'}) && $self->{'-debug'} =~ /^\d$/);
	bless $self, $class;   #BLESS IT!

	return $self;
}

sub _debug {
	my $self = shift;
	my $msg = shift;
	
	warn $msg if $self->{'-debug'};
}

sub sources {
	my $self = shift;
	return wantarray ? @{$self->{'_fetchers'}} : \@{$self->{'_fetchers'}};
}

sub source {
	my $self = shift;
	return $self->{'Source'};
}

sub url {
	my $self = shift;
	return $self->{'Url'};
}

sub order {
	my $self = shift;
	return wantarray ? ($self->{'Source'}) : $self->{'Source'};
}

sub tried {
	return order (@_);
}

sub credits {
	my $self = shift;
	return wantarray ? @{$self->{'Credits'}} : join(', ', @{$self->{'Credits'}});
}

sub message {
	my $self = shift;
	return $self->{'Error'};
}

sub site {
	my $self = shift;
	return $self->{'Site'};
}

# Allow user to specify a different user-agent:
sub agent {
	my $self = shift;
	if (defined $_[0]) {
		$self->{'-agent'} = $_[0];
	} else {
		return $self->{'-agent'};
	}
}

sub cache {
	my $self = shift;
	if (defined $_[0]) {
		$self->{'-cache'} = $_[0];
	} else {
		return $self->{'-cache'};
	}
}

sub image_url {
	return shift->{'image_url'};
}

sub _check_inputs {
	my $self = shift;

	my $Source = $self->{'Source'};
	# reset the error var, change it if an error occurs.
	$self->{'Error'} = 'Ok';
	$self->{'Url'} = '';

	unless ($_[0] && $_[1]) {
		carp($self->{'Error'} = "e:$Source.fetch() called without artist and song!");
		return 0;
	}
	return 1;
}

sub _web_fetch {
	my $self = shift;

	$self->_debug($self->{'Source'}.":_web_fetch($_[0], $_[1]): URL=".$self->{'Url'}."=");
	my $ua = LWP::UserAgent->new(
		ssl_opts => { verify_hostname => 0, },
	);
	$ua->timeout(10);
	$ua->agent($self->{'-agent'});
	$ua->protocols_allowed(['https', 'http']);
	$ua->cookie_jar( {} );
	push @{ $ua->requests_redirectable }, 'GET';
	(my $referer = $self->{'Url'}) =~ s{^(\w+)\:\/\/}{};
	my $protocol = $1;
	$referer =~ s{\/.+$}{\/};
	my $host = $referer;
	$host =~ s{\/$}{};
	$referer = $protocol . '://' . $referer;
	my $req = new HTTP::Request 'GET' => $self->{'Url'};
	$req->header(
		'Accept' =>
			'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
		'Accept-Language'           => 'en-US,en;q=0.5',
		'Accept-Encoding'           => 'gzip, deflate',
		'Connection'                => 'keep-alive',
		'Upgrade-insecure-requests' => 1,
		'Host'                      => $host,
	);

	my $res = $ua->request($req);

	if ($res->is_success) {
		my $lyrics = $self->_parse($res->decoded_content, @_);
		return $lyrics;
	} else {
		my $Source = $self->{'Source'};
		if ($res->status_line =~ /^404/) {
			$self->{'Error'} = "..$Source - Lyrics not found.";
		} else {
			carp($self->{'Error'} = "e:$Source - Failed to retrieve ".$self->{'Url'}
					.' ('.$res->status_line.').');
		}
		return '';
	}
}

sub _remove_accents {
	my $self = shift;
	my $str = shift;

	$str =~ tr/\xc4\xc2\xc0\xc1\xc3\xe4\xe2\xe0\xe1\xe3/aaaaaaaaaa/;
	$str =~ tr/\xcb\xca\xc8\xc9\xeb\xea\xe8\xe9/eeeeeeee/;
	$str =~ tr/\xcf\xcc\xef\xec/iiii/;
	$str =~ tr/\xd6\xd4\xd2\xd3\xd5\xf6\xf4\xf2\xf3\xf5/oooooooooo/;
	$str =~ tr/\xdc\x{0016}\xd9\xda\xfc\x{0016}\xf9\xfa/uuuuuuuu/;
	$str =~ tr/\x{0178}\xdd\xff\xfd/yyyy/;
	$str =~ tr/\xd1\xf1/nn/;
	$str =~ tr/\xc7\xe7/cc/;
	$str =~ s/\xdf/ss/g;

	return $str;
}

# nasty way to strip out HTML
sub _html2text {
	my $self = shift;
	my $str = shift;

	$str =~ s#\<(?:br|\/?p).*?\>#\n#gio;
	$str =~ s#\&gt\;#\>#go;
	$str =~ s#\&lt\;#\<#go;
	$str =~ s#\&amp\;#\&#go;
	$str =~ s#\&quot\;#\"#go;
	$str =~ s#\<.*?\>##go;

	return $str;
}

sub _normalize_lyric_text {
	my $self = shift;
	my $str = shift;

	# normalize Windowsey \r\n sequences:
	$str =~ s/\r+//gs;
	# strip off pre & post padding with spaces:
	$str =~ s/^ +//mg;
	$str =~ s/ +$//mg;
	# clear up repeated blank lines:
	$str =~ s/(\R){2,}/\n\n/gs;
	# and remove any blank top and bottom lines:
	$str =~ s/^\R+//s;
	$str =~ s/\R\R+$/\n/s;
	# add a linefeed to end of lyrics if ther's not one already:
	$str .= "\n"  unless ($str =~ /\n$/s);
	# now fix up for either Windows or Linux/Unix:
	$str =~ s/\R/\r\n/gs  if ($^O =~ /Win/);

	return $str;
}

1

__END__

=head1 NAME

LyricFinder::_Class - Base module containing default methods common to all LyricFinder submodules.

=head1 AUTHOR

This module is Copyright (C) 2017-2021 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

NOTE:  This module is for internal use only by the other LyricFinder modules 
and should not be used directly.  Please see the main module (L<LyricFinder>) 
POD documentation for documentation for all the methods and how to use.

=cut

