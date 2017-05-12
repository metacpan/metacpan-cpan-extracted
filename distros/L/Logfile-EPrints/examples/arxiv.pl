#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib';

use Logfile::arXiv;

my $p = Logfile::Parser->new(
	type=>'Logfile::Hit::Bracket',
	handler=>Logfile::arXiv->new(
	handler=>Logfile::Repeated->new(
	handler=>MyHandler->new()
)));

die "Usage: $0 <logfile>\n" unless @ARGV;
open my $fh, "<:gzip", $ARGV[0];
die "Unable to open log file for reading: $!" unless $fh;
$p->parse_fh($fh);
close $fh;

package MyHandler;

use vars qw( $AUTOLOAD );

sub new { bless {}, shift; }

sub AUTOLOAD {
	my ($self,$hit) = @_;
	$AUTOLOAD =~ s/^.*:://;
	return if $AUTOLOAD =~ /^[A-Z]/;
	printf("%s: %s %s / %s (%s)\n", $AUTOLOAD, $hit->utime||die("Time failed"), ($hit->identifier||'n/a'), $hit->address||die("Address failed"), $hit->country||'Unknown');
}

1;
