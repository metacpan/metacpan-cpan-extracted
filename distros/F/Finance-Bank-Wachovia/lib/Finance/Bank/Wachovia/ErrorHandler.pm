package Finance::Bank::Wachovia::ErrorHandler;
use strict;
use warnings;

our $ERROR;
our @ATTRIBUTES = qw/message/;  # just for those that inherit 

sub new {
	my $class = shift;
	my $self = [];	
	bless $self, $class;
	return $self;
}

sub Error {
	my $self = shift;
	if( ref $self ){
		$self->[0] = shift;
	}
	else{
		$ERROR = shift;
	}
	return undef;
}

sub ErrStr {
	my $self = shift;
	return ref $self ? $self->[0] : $ERROR;	
}


__END__

=begin

=head1 NAME

Finance::Bank::Wachovia::ErrorHandler -- simple exception handling

=head1 SYNOPSIS

This module is meant to be derived from, no time for all docs right now, but it's simple.

=cut
