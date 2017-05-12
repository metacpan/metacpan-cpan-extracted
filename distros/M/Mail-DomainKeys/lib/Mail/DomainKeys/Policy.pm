# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mail::DomainKeys::Policy;

use strict;

our $VERSION = "0.88";

sub new {
	my $type = shift;
	my %prms = @_;

	my $self = {};


	$self->{'NOTE'} = $prms{'Note'};
	$self->{'PLCY'} = $prms{'Policy'};
	$self->{'ADDR'} = $prms{'Address'};
	$self->{'TEST'} = $prms{'Testing'};

	bless $self, $type;
}

sub fetch {
	use Net::DNS;

	my $type = shift;
	my %prms = @_;

	($prms{'Protocol'} eq "dns") or
		return;

	my $host = "_domainkey." . $prms{'Domain'};

	my $rslv = new Net::DNS::Resolver or
		return;
	
	my $strn;
	if (my $resp = $rslv->query($host, "TXT")) {
		foreach my $ans ($resp->answer) {
			$ans->type eq "TXT" and
				$strn = join "", $ans->char_str_list;
		}

	}

	my $self = &parse_string($strn or "") or
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


	$self->testing and
		$text .= "t=y; ";

	$self->policy and
		$text .= "o=" . $self->policy . "; ";
	
	$self->note and
		$text .= "n=" . $self->note . "; ";
	
	$self->address and
		$text .= "r=" . $self->address;

	$text =~ s/;\s*$//;

	length $text and
		return $text;

	return;
}

sub address {
	my $self = shift;

	(@_) and
		$self->{'ADDR'} = shift;

	$self->{'ADDR'};
}

sub note {
	my $self = shift;

	(@_) and 
		$self->{'NOTE'} = shift;

	$self->{'NOTE'};
}

sub policy {
	my $self = shift;

	(@_) and
		$self->{'PLCY'} = shift;

	$self->{'PLCY'};
}

sub signall {
	my $self = shift;

	$self->policy and $self->policy eq "-" and
		return 1;

	return;
}

sub signsome {
	my $self = shift;

	$self->policy or
		return 1;

	$self->policy eq "~" and
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

	my $tags = {'PLCY' => "~"};

	foreach my $tag (split /;/, $text) {
		$tag =~ s/^\s*|\s*$//g;

		foreach ($tag) {
			/^n=(.*)$/ and
				$tags->{'NOTE'} = $1;
			/^o=(\~|\-)$/ and
				$tags->{'PLCY'} = $1;
			/^r=([\w\@\.]+)$/ and
				$tags->{'ADDR'} = $1;
			/^t=y$/ and
				$tags->{'TEST'} = 1;
		}
	}

	return $tags;
}

1;
