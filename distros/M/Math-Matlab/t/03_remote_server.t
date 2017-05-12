#!/usr/bin/perl -w

BEGIN {
	use lib qw ( t );
}
use strict;
use Test::More tests => 12;

## read server configuration
use vars qw( $SERVER_CONFIG );
require "./server.config";
## avoid the 'used only once' warnings
$Math::Matlab::Remote::URI = $Math::Matlab::Remote::USER = $Math::Matlab::Remote::PASS = '';
$Math::Matlab::Remote::URI = $SERVER_CONFIG->{URI};
$Math::Matlab::Remote::USER = $SERVER_CONFIG->{USER};
$Math::Matlab::Remote::PASS = $SERVER_CONFIG->{PASS};

require_ok('Math::Matlab::Remote');

my $t = 'new';
my $matlab = Math::Matlab::Remote->new;
isa_ok( $matlab, 'Math::Matlab::Remote', $t );

SKIP: {
	my $reason = '';
	if ($Math::Matlab::Remote::URI) {
		eval { require LWP::UserAgent };
		if ($@) {
			$reason = "Required package LWP::UserAgent not found.";
		}
	} else {
		$reason = "Server not configured in 'server.config'";
	}

	skip $reason, 10	if $reason;
	
	my $code = "fprintf( '\%.1f\\n', foo(5));";
	
	$t = 'execute';
	my $rv = $matlab->execute($code);
	ok( $rv, $t );
	
	$t = 'fetch_result';
	my $got = $matlab->fetch_result	if $rv;
	cmp_ok( $got, '==', 25, $t );
	
	print $matlab->err_msg	unless $rv;
	
	$t = 'new( { uri => ... } )';
	$matlab = Math::Matlab::Remote->new( {	uri => $Math::Matlab::Remote::URI . '/test' } );
	ok( $matlab, $t );
	
	$t = 'execute($code)';
	$rv = $matlab->execute( $code );
	ok( $rv, $t );
	
	$t = 'fetch_result';
	$got = $matlab->fetch_result	if $rv;
	cmp_ok( $got, '==', 26, $t );
	
	$t = 'execute($code, $rel_mwd)';
	$rv = $matlab->execute( $code, 'remote' );
	ok( $rv, $t );
	
	$t = 'fetch_result';
	$got = $matlab->fetch_result	if $rv;
	cmp_ok( $got, '==', 27, $t );
	
	print $matlab->err_msg	unless $rv;
	
	$t = 'new( { uri => ... } )';
	$matlab = Math::Matlab::Remote->new( {	uri => $Math::Matlab::Remote::URI . '/test/remote' } );
	ok( $matlab, $t );
	
	$t = 'execute($code)';
	$rv = $matlab->execute( $code );
	ok( $rv, $t );
	
	$t = 'fetch_result';
	$got = $matlab->fetch_result	if $rv;
	cmp_ok( $got, '==', 27, $t );
	
	print $matlab->err_msg	unless $rv;
}

1;

=pod

=head1 NAME

03_remote_server.t - Tests for Math::Matlab::Remote.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 LIST OF TESTS

=head1 CHANGE HISTORY

=head1 COPYRIGHT

Copyright (c) 2002 PSERC. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

  Ray Zimmerman, <rz10@cornell.edu>

=head1 SEE ALSO

 perl(1)

=cut
