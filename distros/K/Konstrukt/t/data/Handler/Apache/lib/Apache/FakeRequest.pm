#!/usr/bin/perl

#own fake request package, as Apache::FakeRequest only gets shipped with mod_perl 1

package Apache::FakeRequest;

use strict;
use warnings;
use vars qw/$AUTOLOAD/;
#use base 'Apache::FakeRequest';
#see also Apache::FakeRequest

sub new {
	my $class = shift;
	bless {@_}, $class;
}

sub headers_in {
	return ( Cookie => '' );
}

sub reset_print_buffer {
	my $self = shift;
	$self->{printed} = '';
}

sub print {
	my $self = shift;
	$self->{printed} .= join '', @_;
}

sub AUTOLOAD {
	my ($self, @args) = @_;
	
	my $sub = substr($AUTOLOAD, length(__PACKAGE__ . "::"));
	#warn "---- apa: $sub";
	
	$self->{$sub} = $args[0] if @args;
	
	return $self->{$sub};
}

1;
