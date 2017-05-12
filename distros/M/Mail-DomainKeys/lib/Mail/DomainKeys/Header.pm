# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mail::DomainKeys::Header;

use strict;

our $VERSION = "0.88";

sub new {
	my $type = shift;
	my %prms = @_;

	my $self = {};


	$self->{'ATTR'} = $prms{'Key'};
	$self->{'SIGN'} = $prms{'Signed'};
	$self->{'VALU'} = $prms{'Value'};
	$self->{'LINE'} = $prms{'Line'};

	bless $self, $type;
}

sub parse {
	my $type = shift;
	my %prms = @_;

	my $self = {};


	$prms{'String'} or
		return;

	$self->{'LINE'} = $prms{'String'};
	$self->{'SIGN'} = $prms{'Signed'};

	bless $self, $type;
}

sub append {
	my $self = shift;
	my $cont = shift;

	$self->line($self->line . $cont);
}

sub unfolded {
	my $self = shift;

	my $line = $self->line;
	$line =~ s/\n//g;

	return $line . "\n";
}

sub vunfolded {
	my $self = shift;

	my $valu = $self->value;
	$valu =~ s/\n//g;

	return $valu . "\n";
}

sub key {
	my $self = shift;

	$self->line =~ /^([!-9;-\176]+)[ \t]*:/s and
		return $1;
	
	return;
}

sub line {
	my $self = shift;

	(@_) and
		$self->{'LINE'} = shift;

	$self->{'LINE'};
}

sub signed {
	my $self = shift;

	(@_) and
		$self->{'SIGN'} = shift;

	$self->{'SIGN'};
}

sub value {
	my $self = shift;

	$self->line =~ /^[!-9;-\176]+[ \t]*:(.*)\z/s and
		return $1;

	return;
}

1;
