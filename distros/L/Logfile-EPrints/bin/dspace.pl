#!/usr/bin/perl

use lib 'lib';

use Logfile::EPrints;
use Logfile::EPrints::Mapping::DSpace;

my $parser = Logfile::EPrints::Parser->new(
	handler => Logfile::EPrints::Mapping::DSpace->new(
	identifier => 'oai:dpsace:',
	handler => MyHandler->new
));

die "Usage: $0 <filename>\n" unless @ARGV;

open(my $fh, "<", shift @ARGV) or die $!;
$parser->parse_fh( $fh );
close($fh);

package MyHandler;

sub new
{
	bless {}, shift;
}

sub fulltext
{
	my( $self, $hit ) = @_;

	print "Fulltext: ".$hit->identifier."\n";
}

sub abstract
{
	my( $self, $hit ) = @_;

	print "Abstract: ".$hit->identifier."\n";
}
