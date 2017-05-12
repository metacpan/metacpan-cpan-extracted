# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mail::DomainKeys::Signature;

use strict;

our $VERSION = "0.88";

sub new {
	my $type = shift;
	my %prms = @_;
	my $self = {};

	$self->{'ALGO'} = $prms{'Algorithm'};
	$self->{'DATA'} = $prms{'Signature'};
	$self->{'METH'} = $prms{'Method'};
	$self->{'DOMN'} = $prms{'Domain'};
	$self->{'HDRS'} = $prms{'Headers'};
	$self->{'PROT'} = $prms{'Query'};
	$self->{'SLCT'} = $prms{'Selector'};
	$self->{'SHDR'} = $prms{'SignHeaders'};
	$self->{'SIGN'} = $prms{'Signing'};
	$self->{'CFWS'} = $prms{'FWS'};

	bless $self, $type;
}

sub parse {
	my $type = shift;
	my %prms = @_;
	my $self = {};


	foreach my $tag (split /;/, $prms{"String"}) {
		$tag =~ s/^\s*|\s*$//g;

		foreach ($tag) {
			/^a=(rsa-sha1)$/i and
				$self->{'ALGO'} = lc $1;
			/^b=([A-Za-z0-9\+\/\=\s]+)$/ and
				$self->{'DATA'} = $1;
			/^c=(nofws|simple)$/i and
				$self->{'METH'} = lc $1;
			/^d=([A-Za-z0-9\-\.]+)$/ and
				$self->{'DOMN'} = lc $1;
			/^h=(.*)$/s and
				$self->{'HDRS'} = lc $1;
			/^q=(dns)$/i and
				$self->{'PROT'} = lc $1;
			/^s=(\S+)$/ and
				$self->{'SLCT'} = $1;
		}
	}

	bless $self, $type;	
}

sub wantheader {
	my $self = shift;
	my $attr = shift;

       # we are signing, and a list of headers to sign was specified
       if ($self->signheaderlist) {
               foreach my $key ($self->signheaderlist) {
                       lc $attr eq lc $key and
                               return 1;
               }

               return;
	}

       # we are verifying
       if ($self->headerlist) {
               foreach my $key ($self->headerlist) {
                       lc $attr eq lc $key and
                               return 1;
               }

               return;
       }

       # we are signing and a list of headers to sign was not specified,
       # or we are verifying and the DomainKeys-Signature header does not
       # have a h= term
       return 1;
}

sub as_string {
	my $self = shift;

	my $text;

	$self->algorithm and
		$text .= "a=" . $self->algorithm . "; ";

	$self->headerlist and
		$text .= "h=" . $self->headerlist . "; ";

	$text .= "q=" . $self->protocol . "; ";
	$text .= "c=" . $self->method . "; ";
	$text .= "s=" . $self->selector . "; ";
	$text .= "d=" . $self->domain . "; ";
	$text .= "b=" . $self->signature;

	if (defined (my $cfws = $self->fws)) {
		require Text::Wrap;

		local $Text::Wrap::columns = 78;

		$text = Text::Wrap::wrap("", $cfws, $text);
		$text .= "\n";
	}
		
	return $text;
}

sub sign {
	use MIME::Base64;

	my $self = shift;
	my %prms = @_;

	$self->method($prms{'Method'}) if $prms{'Method'};
	$self->selector($prms{'Selector'}) if $prms{'Selector'};
	$self->private($prms{'Private'}) if $prms{'Private'};

	my $text = $prms{'Text'} or
		$self->errorstr("no text given"),
		return;

	$self->method or
		$self->errorstr("no method specified"),
		return;

	$self->private or
		$self->errorstr("no private key specified"),
		return;

	$self->selector or
		$self->errorstr("no selector specified"),
		return;

	$self->domain or
		$self->errorstr("no domain specified"),
		return;

	$self->protocol or $self->protocol("dns");
	$self->algorithm or $self->algorithm("rsa-sha1");

	# d=... The value in this tag MUST match the domain of the sending
	# email address or MUST be one of the parent domains of the sending
	# email address. Domain name comparison is case insensitive.
	my $signing_domain = $self->domain;
	$prms{'Sender'}->host =~ /(^|\.)\Q$signing_domain\E\z/i or
		$self->errorstr("domain does not match address"),
		return;

	my $sign = $self->private->sign($text);
	my $signb64 = encode_base64($sign, "");

	$self->signature($signb64);

	$self->status("good");

	return 1;
}


sub verify {
	use Mail::DomainKeys::Key::Public;
	use MIME::Base64;

	my $self = shift;
	my %prms = @_;


	$self->status("bad format"),

	$self->selector or
		$self->errorstr("no selector specified"),
		return;

	$self->domain or
		$self->errorstr("no domain specified"),
		return;
	
	unless ($self->public) {
		my $pubk = fetch Mail::DomainKeys::Key::Public(
			Protocol => $self->protocol,
			Selector => $self->selector,
			Domain => $self->domain) or
				$self->status("no key"),
				$self->errorstr("no public key available"),
				return;

		$pubk->revoked and
			$self->status("revoked"),
			$self->errorstr("public key has been revoked"),
			return;

		$self->public($pubk);
	}

	$self->status("bad");

	# d=... The value in this tag MUST match the domain of the sending
	# email address or MUST be one of the parent domains of the sending
	# email address. Domain name comparison is case insensitive.
	my $signing_domain = $self->domain;
	$prms{'Sender'}->host =~ /(^|\.)\Q$signing_domain\E\z/i or
		$self->errorstr("domain does not match address"),
		return;

	$prms{'Sender'}->host eq $self->domain or
		$self->errorstr("domain does not match address"),
		return;

	$self->public->granularity and
		$prms{'Sender'}->user ne $self->public->granularity and
			$self->errorstr("granularity does not match address"),
			return;

	$self->public->verify(Text => $prms{'Text'},
		Signature => decode_base64($self->signature)) and
			$self->errorstr(undef),
			$self->status("good"),
			return 1;

	$self->errorstr("signature invalid");

	return;
}

sub algorithm {
	my $self = shift;

	@_ and
		$self->{'ALGO'} = shift;

	$self->{'ALGO'};
}	

sub domain {
	my $self = shift;

	@_ and
		$self->{'DOMN'} = shift;

	$self->{'DOMN'};
}	

sub errorstr {
	my $self = shift;

	@_ and
		$self->{'ESTR'} = shift;

	$self->{'ESTR'};
}

sub fws {
	my $self = shift;

	@_ and
		$self->{'CFWS'} = shift;

	return $self->{'CFWS'};
}

sub headerlist {
	my $self = shift;

	@_ and
		$self->{'HDRS'} = shift;

	if (wantarray and $self->{'HDRS'}) {
		my @list = split /[ \t]*:[ \t]*/, $self->{'HDRS'};
		return @list;
	}

	$self->{'HDRS'};
}	

sub method {
	my $self = shift;

	@_ and
		$self->{'METH'} = shift;

	$self->{'METH'};
}	

sub public {
	my $self = shift;

	@_ and
		$self->{'PBLC'} = shift;

	$self->{'PBLC'};
}
		
sub private {
	my $self = shift;

	@_ and
		$self->{'PRIV'} = shift;

	$self->{'PRIV'};
}
		
sub protocol {
	my $self = shift;

	@_ and
		$self->{'PROT'} = shift;

	$self->{'PROT'};
}	

sub selector {
	my $self = shift;

	@_ and
		$self->{'SLCT'} = shift;

	$self->{'SLCT'};
}	

sub signature {
	my $self = shift;

	@_ and
		$self->{'DATA'} = shift;

	$self->{'DATA'};
}	

sub signheaderlist {
       my $self = shift;

       @_ and
               $self->{'SHDR'} = shift;

       if (wantarray and $self->{'SHDR'}) {
               my @list = split /:/, $self->{'SHDR'};
               return @list;
       }

       $self->{'SHDR'};
}

sub signing {
	my $self = shift;

	@_ and
		$self->{'SIGN'} = shift;

	$self->{'SIGN'};
}	

sub status {
	my $self = shift;

	@_ and
		$self->{'STAT'} = shift;

	$self->{'STAT'};
}	

sub testing {
	my $self = shift;

	$self->public and $self->public->testing and
		return 1;

	return;
}


1;
