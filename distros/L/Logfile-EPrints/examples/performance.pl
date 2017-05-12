#!/usr/bin/perl -w

use strict;

use Benchmark;
use Logfile::EPrints;
use Logfile::EPrints::RobotsFilter;

my $code = sub {
open my $fh, 'examples/ecs.log' or die $!;
my $parser = Logfile::EPrints::Parser->new(
	handler=>Logfile::EPrints->new(
		identifier=>'oai:eprints.ecs.soton.ac.uk:',
	handler=>Logfile::EPrints::Repeated->new(
	handler=>Logfile::EPrints::RobotsFilter->new(
	handler=>Handler->new,
))));
$parser->parse_fh($fh);
close($fh);
};

timethis(10, $code);

package Handler;

use vars qw( $AUTOLOAD );

sub new {
	my( $class, %self ) = @_;
	bless \%self, $class;
}

sub DESTROY {}

sub AUTOLOAD {}
