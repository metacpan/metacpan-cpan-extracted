# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mail::DomainKeys::Key::Public;

use base "Mail::DomainKeys::Key";

use strict;

our $VERSION = "0.88";

sub new {
	my $type = shift;
	my %prms = @_;

	my $self = {};

	$self->{'GRAN'} = $prms{'Granularity'};
	$self->{'NOTE'} = $prms{'Note'};
	$self->{'TEST'} = $prms{'Testing'};
	$self->{'TYPE'} = ($prms{'Type'} or "rsa");
	$self->{'DATA'} = $prms{'Data'};

	bless $self, $type;
}

sub load {
	my $type = shift;
	my %prms = @_;

	my $self = {};


	$self->{'GRAN'} = $prms{'Granularity'};
	$self->{'NOTE'} = $prms{'Note'};
	$self->{'TEST'} = $prms{'Testing'};
	$self->{'TYPE'} = ($prms{'Type'} or "rsa");

	if ($prms{'File'}) {	
		my @data;
		open FILE, "<$prms{'File'}" or
			return;
		while (<FILE>) {
			chomp;
			/^---/ and
				next;
			push @data, $_;
		}
		$self->{'DATA'} = join '', @data;
	} else {
		return;
	}

	bless $self, $type;
}

sub fetch {
	use Net::DNS;

	my $type = shift;
	my %prms = @_;

	my $strn;


	($prms{'Protocol'} eq "dns") or
		return;

	my $host = $prms{'Selector'} . "._domainkey." . $prms{'Domain'};

	my $rslv = new Net::DNS::Resolver or
		return;
	
	my $resp = $rslv->query($host, "TXT") or
		return;

	foreach my $ans ($resp->answer) {
		next unless $ans->type eq "TXT";
		$strn = join "", $ans->char_str_list;
	}

	$strn or
		return;

	my $self = &parse_string($strn) or
		return;

	bless $self, $type;	
}

sub parse {
	my $type = shift;
	my %prms = @_;


	my $self = &parse_string($prms{'String'}) or
		return;

	bless $self, $type;	
}

sub as_string {
	my $self = shift;

	my $text;


	$self->granularity and
		$text .= "g=" . $self->granularity . "; ";
	
	$self->type and
		$text .= "k=" . $self->type . "; ";

	$self->note and
		$text .= "n=" . $self->note . "; ";
	
	$self->testing and
		$text .= "t=y; ";

	$text .= "p=" . $self->data;
	
	length $text and
		return $text;

	return;
}

sub convert {
	use Crypt::OpenSSL::RSA;

	my $self = shift;


	$self->data or
		return;

	# have to PKCS1ify the pubkey because openssl is too finicky...
	my $cert = "-----BEGIN PUBLIC KEY-----\n";

	for (my $i = 0; $i < length $self->data; $i += 64) {
		$cert .= substr $self->data, $i, 64;
		$cert .= "\n";
	}	

	$cert .= "-----END PUBLIC KEY-----\n";

	my $cork;
	
	eval {
		$cork = new_public_key Crypt::OpenSSL::RSA($cert);
	};

	$@ and
		$self->errorstr($@),
		return;

	$cork or
		return;

	# segfaults on my machine
#	$cork->check_key or
#		return;

	$self->cork($cork);

	return 1;
}

sub verify {
	my $self = shift;
	my %prms = @_;


	my $rtrn = eval {
		$self->cork->verify($prms{'Text'}, $prms{'Signature'});
	}; 

	$@ and
		$self->errorstr($@),
		return;
	
	return $rtrn;
}

sub granularity {
	my $self = shift;

	(@_) and 
		$self->{'GRAN'} = shift;

	$self->{'GRAN'};
}

sub note {
	my $self = shift;

	(@_) and 
		$self->{'NOTE'} = shift;

	$self->{'NOTE'};
}

sub revoked {
	my $self = shift;

	$self->data or
		return 1;

	return;
}

sub testing {
	my $self = shift;

	(@_) and 
		$self->{'TEST'} = shift;

	$self->{'TEST'};
}

sub parse_string {
	my $text = shift;

	my %tags;


	foreach my $tag (split /;/, $text) {
		$tag =~ s/^\s*|\s*$//g;

		foreach ($tag) {
			/^g=(\S+)$/ and
				$tags{'GRAN'} = $1;
			/^k=(rsa)$/i and
				$tags{'TYPE'} = lc $1;
			/^n=(.*)$/ and
				$tags{'NOTE'} = $1;
			/^p=([A-Za-z0-9\+\/\=]+)$/ and
				$tags{'DATA'} = $1;
			/^t=y$/i and
				$tags{'TEST'} = 1;
		}
	}

	return \%tags;
}

1;
