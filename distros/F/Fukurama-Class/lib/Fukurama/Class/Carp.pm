package Fukurama::Class::Carp;
our $VERSION = 0.01;
use strict;
use warnings;

use Carp();

=head1 NAME

Fukurama::Class::Carp - Carp-Adapter to easy extend the carp-level

=head1 VERSION

Version 0.01 (beta)

=head1 SYNOPSIS
 
 use Fukurama::Class::Carp;
  
 sub foo {
 	bar();
 }
 sub bar {
 	baz();
 }
 sub baz {
 	# would croak in foo()
 	croak('its not my fault', 1);
 }
 
=head1 DESCRIPTION

This module provides a simple method to change the $Carp::CarpLevel locally.
This is a helperclass for Fukurama::Class.

=head1 CONFIG

-

=head1 EXPORT

=over 4

=item _carp( message:STRING, [ addCarpLevel:INT ] ) return:VOID

It's like Carp::carp(). It will warn about an error in the callers context.
But you can increase the carp-level with a parameter

=item _croak( message:STRING, [ addCarpLevel:INT ] ) return:VOID

It's like Carp::croak(). It will die an error in the callers context.
But you can increase the carp-level with a parameter

=back

=head1 METHODS

-

=head1 AUTHOR, BUGS, SUPPORT, ACKNOWLEDGEMENTS, COPYRIGHT & LICENSE

see perldoc of L<Fukurama::Class>

=cut

# AUTOMAGIC void
sub import {
	my $class = $_[0];
	
	no strict 'refs';
	
	my ($caller) = caller(0);
	*{$caller . '::_carp'} = \&_carp;
	*{$caller . '::_croak'} = \&_croak;
	return;
}
# DIRECT void
sub _carp {
	my $msg = $_[0];
	my $level = $_[1];
	
	$level ||= 0;
	
	no strict 'refs';
	
	my ($caller) = caller(0);
	local $Carp::CarpLevel = $Carp::CarpLevel + $level + 1;
	Carp::carp($msg);
	return;
}
# DIRECT void
sub _croak {
	my $msg = $_[0];
	my $level = $_[1];
	
	$level ||= 0;
	
	local $Carp::CarpLevel = $Carp::CarpLevel + $level + 1;
	Carp::croak($msg);
	return;
}
1;
