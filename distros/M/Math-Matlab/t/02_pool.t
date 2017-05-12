#!/usr/bin/perl -w

BEGIN {
	use lib qw ( t );
}
use strict;
use Test::More tests => 10;
use Cwd qw( abs_path );

use vars qw( $MATLAB_CMD $HAVE_LOCAL_MATLAB );
require "matlab.config";

$Math::Matlab::Pool::MEMBERS = $Math::Matlab::Pool::SYNC_FILE = '';
$Math::Matlab::Pool::MEMBERS = [
	{	class => 'Math::Matlab::Local',
		args => { root_mwd => abs_path( './t/mwd0' ), cmd => $MATLAB_CMD } },
	{	class => 'Math::Matlab::Local',
		args => { root_mwd => abs_path( './t/mwd1' ), cmd => $MATLAB_CMD } },
	{	class => 'Math::Matlab::Local',
		args => { root_mwd => abs_path( './t/mwd2' ), cmd => $MATLAB_CMD } }
];
$Math::Matlab::Pool::SYNC_FILE = abs_path( './t/sync_file.txt');

require_ok('Math::Matlab::Pool');
require_ok('Math::Matlab::Local');

my $t = 'new';
my $matlab = Math::Matlab::Pool->new;
isa_ok( $matlab, 'Math::Matlab::Pool', $t );

SKIP: {
	skip "'$MATLAB_CMD' does not start Matlab", 7	unless $HAVE_LOCAL_MATLAB;

	my ($rv, $got);
	my @results = ( 25, 26, 27, 25, 26, 27 );
	
	foreach my $i (0..5) {
		$t = 'execute($code): ' . $i;
		$rv = $matlab->execute( "fprintf( '\%.1f\\n', foo(5));" );
		$got = $matlab->fetch_result	if $rv;
		cmp_ok( $got, '==', $results[$i], $t );
		print $matlab->err_msg	unless $rv;
	}
	
	$t = 'execute($code, $rel_mwd)';
	my $matlab0 = $matlab->members->[0];
	$matlab0->root_mwd( abs_path( './t' ));
	$rv = $matlab->execute( "fprintf( '\%.1f\\n', foo(5));", 'mwd1' );
	$got = $matlab->fetch_result	if $rv;
	cmp_ok( $got, '==', 26, $t );
	print $matlab->err_msg	unless $rv;
	
	unlink $matlab->sync_file;
}

1;

=pod

=head1 NAME

02_pool.t - Tests for Math::Matlab::Pool.

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
