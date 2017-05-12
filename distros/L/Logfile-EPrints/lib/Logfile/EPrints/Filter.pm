package Logfile::EPrints::Filter;

=head1 NAME

Logfile::EPrints::Filter - base class for filters

=head1 SYNOPSIS

A minimal filter that removes all abstract requests:

	package Logfile::EPrints::Filter::Custom;

	our @ISA = qw( Logfile::EPrints::Filter );

	sub abstract {}

	1;

=cut

use strict;

use vars qw( $AUTOLOAD );

sub new
{
	my( $class, %self ) = @_;
	bless \%self, $class;
}

sub AUTOLOAD
{
	return if $AUTOLOAD =~ /[A-Z]$/;
	$AUTOLOAD =~ s/^.*:://;
	$_[0]->{handler}->$AUTOLOAD( $_[1] );
}

package Logfile::EPrints::Filter::Debug;

use strict;

use vars qw( $AUTOLOAD );

our @ISA = qw( Logfile::EPrints::Filter );

sub AUTOLOAD
{
	return if $AUTOLOAD =~ /[A-Z]$/;
	$AUTOLOAD =~ s/^.*:://;
	my( $self, $hit ) = @_;
	$self->{requests}->{$AUTOLOAD}++;
	for( sort keys(%{$self->{requests}}) ) {
		print STDERR "+" if $_ eq $AUTOLOAD;
		print STDERR "$_ [".$self->{requests}->{$_}."] ";
	}
	print STDERR "\r";
	$self->{handler}->$AUTOLOAD( $hit );
}

1;
