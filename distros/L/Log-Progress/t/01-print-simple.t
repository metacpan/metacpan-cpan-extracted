#! /usr/bin/env perl
use strict;
use warnings;
use Test::More 0.96;

use_ok 'Log::Progress' or BAIL_OUT;

my $out= '';
my $p= Log::Progress->new(to => sub { $out .= (shift) . "\n" });
$p->at(0);

is( $out, "progress: 0.00\n", 'log via coderef' );

$out= '';
open my $old_stderr, '>&STDERR' or die $!;
close STDERR; open STDERR, '>', \$out or die $!;
$p= Log::Progress->new();
$p->at(0);
close STDERR; open STDERR, '>&', $old_stderr or die $!;

is( $out, "progress: 0.00\n", 'log via STDERR' );

$out= '';
open my $out_fh, '>', \$out or die $!;
$p= Log::Progress->new(to => $out_fh);
$p->at(0);

is( $out, "progress: 0.00\n", "log via filehandle" );

$out= '';
{
package TestLogger;
	sub new { bless {}, shift }
	sub info { $out .= $_[1]."\n" }
};

$p= Log::Progress->new(to => TestLogger->new);
$p->at(0);

is( $out, "progress: 0.00\n", "Log via logger object" );

done_testing;
