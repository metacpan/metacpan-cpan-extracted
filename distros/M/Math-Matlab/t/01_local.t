#!/usr/bin/perl -w

BEGIN {
	use lib qw ( t );
	use vars qw ( $ntests );
	$ntests = 20;
}
use strict;
use Test::More tests => $ntests;
use Cwd qw( abs_path );

use vars qw( $MATLAB_CMD $HAVE_LOCAL_MATLAB );
require "matlab.config";
$Math::Matlab::Local::CMD = $MATLAB_CMD;

require_ok('Math::Matlab::Local');

my $t = 'new';
my $matlab = Math::Matlab::Local->new;
isa_ok( $matlab, 'Math::Matlab::Local', $t );

SKIP: {
	skip "'$MATLAB_CMD' does not start Matlab", $ntests - 2
		unless $HAVE_LOCAL_MATLAB;

	$t = "'$MATLAB_CMD' successfully starts Matlab.";
	ok($HAVE_LOCAL_MATLAB, $t);
	
	my $code_runtime_err = <<ENDOFCODE;
fprintf('Hello error\\n');
fprintf('%d', sqrt);
ENDOFCODE

	my $code = <<ENDOFCODE;
x = 1:10;
y = x .^ 2;
fprintf('%d\\t%d\\n', [x; y]);
ENDOFCODE

	my $expected = <<ENDOFRESULT;
1	1
2	4
3	9
4	16
5	25
6	36
7	49
8	64
9	81
10	100
ENDOFRESULT

	my $code_stderr = <<ENDOFCODE;
fprintf(1, '\%s\\n', 'Hello STDOUT');
fprintf(2, '\%s\\n', 'Hello STDERR');
ENDOFCODE

	my $expected_stderr = <<ENDOFRESULT;
Hello STDOUT
Hello STDERR
ENDOFRESULT

	$t = 'MATLAB LAUNCH FAILURE : ';
	my $cmd = $matlab->cmd;
	$matlab->cmd("echo 'hello'");
	my $rv = $matlab->execute($code);
	ok( !$rv, $t . 'execute' );
	my $got = $matlab->err_msg;
	(my $fine) = $got =~ /MATLAB LAUNCH FAILURE/;
	ok( $fine, $t . 'err_msg' );
	print $got	unless $fine;
	$matlab->remove_files;

	$t = 'normal : ';
	$matlab->cmd($cmd);
	$rv = $matlab->execute($code);
	ok( $rv, $t . 'execute' );
	$got = $matlab->fetch_result	if $rv;
	is( $got, $expected, $t . 'fetch_result' );
	print $matlab->err_msg	unless $rv;
	
	$t = 'stderr : ';
	$rv = $matlab->execute($code_stderr);
	ok( $rv, $t . 'execute' );
	$got = $matlab->fetch_result	if $rv;
	is( $got, $expected_stderr, $t . 'fetch_result' );
	print $matlab->err_msg	unless $rv;
	
	$t = 'MATLAB INITIALIZATION ERROR : ';
	package Crash;
	use base qw(Math::Matlab::Local);
	sub _create_wrapper_file {
		my ($self) = @_;
		
		my $fn = $self->wrapper_fn;
		open(Matlab::IO, ">$fn") || die "Couldn't open '$fn'";
		print Matlab::IO "quit;\n";
		close(Matlab::IO);
	
		return 1;
	}
	package main;
	my $matlab2 = Crash->new;
	$rv = $matlab2->execute($code);
	ok( !$rv, $t . 'execute' );
	$got = $matlab2->err_msg;
	($fine) = $got =~ /MATLAB INITIALIZATION ERROR/;
	ok( $fine, $t . 'err_msg' );
	print $got	unless $fine;
	$matlab2->remove_files;
	
	$t = 'MATLAB RUNTIME ERROR : ';
	$rv = $matlab->execute($code_runtime_err);
	ok( !$rv, $t . 'execute' );
	$got = $matlab->err_msg;
	($fine) = $got =~ /MATLAB RUNTIME ERROR/;
	ok( $fine, $t . 'err_msg' );
	print $got	unless $fine;
	$matlab->remove_files;
		
	$t = 'new( { root_mwd => ... } )';
	$matlab = Math::Matlab::Local->new( {	root_mwd => abs_path('./t/mwd0'),
											cmd      => $Math::Matlab::Local::CMD	} );
	ok( $matlab, $t );
	
	$t = 'execute($code)';
	$rv = $matlab->execute( "fprintf( '\%.1f\\n', foo(5));" );
	ok( $rv, $t );
	
	$t = 'fetch_result';
	$got = $matlab->fetch_result	if $rv;
	cmp_ok( $got, '==', 25, $t );
	print $matlab->err_msg	unless $rv;
	
	$t = 'execute($code, $rel_mwd)';
	$matlab = Math::Matlab::Local->new( {	root_mwd => abs_path('./t'),
											cmd      => $Math::Matlab::Local::CMD	} );
	$rv = $matlab->execute( "fprintf( '\%.1f\\n', foo(5));", 'mwd1' );
	ok( $rv, $t );
	
	$t = 'fetch_result';
	$got = $matlab->fetch_result	if $rv;
	cmp_ok( $got, '==', 26, $t );
	print $matlab->err_msg	unless $rv;

	$t = 'existing script : ';
	$rv = $matlab->execute(undef, undef, 'existing.m');
	ok( $rv, $t . 'execute' );
	$got = $matlab->fetch_result	if $rv;
	is( $got, "Hello Existing\n", $t . 'fetch_result' );
	print $matlab->err_msg	unless $rv;
}

1;

=pod

=head1 NAME

01_local.t - Tests for Math::Matlab::Local.

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
