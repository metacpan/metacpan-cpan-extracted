#!perl

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use warnings;

use Test::More tests => 6;

my $module = 'Devel::TraceMethods';
use_ok( $module );

package TraceMe;

sub foo {}

sub bar {}

package TraceMe2;

@TraceMe2::ISA = 'TraceMe';

sub new
{
	bless {}, $_[0];
}

sub bar { join(' ', @_) }

package main;

Devel::TraceMethods->import( 'TraceMe2' );

# try replacing the logging sub
my $result = '';
Devel::TraceMethods->callback(sub { $result = $_[0] });
my $baz    = TraceMe2->bar( 'hi' );
is( $result, 'TraceMe2::bar', 'Trace should respect the registered callback' );
is( $baz, 'TraceMe2 hi', '... not manipulating wrapped @_' );

Devel::TraceMethods->callback(sub { @_ = reverse @_; $result = join(' ', @_ )});
$baz      = TraceMe2->bar( 'hi' );
is( $result, 'hi TraceMe2 TraceMe2::bar',
	'Trace should be able to access all of @_' );
is( $baz, 'TraceMe2 hi', '... but working on a copy' );

Devel::TraceMethods->import( TraceMe => sub { $result = 'boo' } );
TraceMe->foo();
is( $result, 'boo', 'import() should be able to set per-package callback' );
