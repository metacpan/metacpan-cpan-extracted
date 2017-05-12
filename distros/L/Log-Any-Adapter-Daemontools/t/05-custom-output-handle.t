#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Carp 'confess';
use Log::Any;
use Log::Any::Adapter;
use Log::Any::Adapter::Util ':levels';

use_ok( 'Log::Any::Adapter::Daemontools' ) || BAIL_OUT;

my $buf;

my $cfg= Log::Any::Adapter::Daemontools->new_config;
my $log= Log::Any->get_logger(category => 'testing');
Log::Any::Adapter->set( 'Daemontools', config => $cfg );

subtest output_globref => sub {
	my $buf;
	open OUT, '>', \$buf or die "Can't open string as file handle\n";
	$cfg->output(\*OUT);
	
	$log->warn("Testing");
	is( $buf, "warning: Testing\n", 'single line message' );

	$log->warn("Testing2\nTesting3\n");
	is( $buf, "warning: Testing\nwarning: Testing2\nwarning: Testing3\n", 'multi line message' );
	
	done_testing;
};

package Test::PrintableObject;
sub new { bless {}, shift; }
sub print { shift->{buf} .= join(',', @_); }
sub buf { shift->{buf} }
package main;

subtest output_object => sub {
	my $out= Test::PrintableObject->new;
	$cfg->output($out);
	
	$log->warn("Testing");
	is( $out->buf, "warning: Testing\n", 'single line message' );

	$log->warn("Testing2\nTesting3\n");
	is( $out->buf, "warning: Testing\nwarning: Testing2\n,warning: Testing3\n", 'multi line message' );
	
	done_testing;
};

subtest output_coderef => sub {
	my $buf= '';
	my $out= sub { $buf .= join(':', @_); };
	$cfg->output($out);
	
	$log->warn("Testing");
	is( $buf, "warning: Testing\n", 'single line message' );

	$log->warn("Testing2\nTesting3\n");
	is( $buf, "warning: Testing\nwarning: Testing2\n:warning: Testing3\n", 'multi line message' );
	
	done_testing;
};

done_testing;
