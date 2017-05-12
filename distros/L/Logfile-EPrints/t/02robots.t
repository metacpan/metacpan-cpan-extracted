use Test::More tests => 2;

use strict;
use warnings;

use Logfile::EPrints;
ok(1);

unlink('examples/robots.db.dir');
unlink('examples/robots.db.pag');

open my $fh, "<examples/ecs.log" or die $!;
my $p = Logfile::EPrints::Parser->new(
	handler=>my $robots = Logfile::EPrints::Filter::RobotsTxt->new(
		file=>'examples/robots.db',
		handler=>Handler->new()
	)
);
$p->parse_fh($fh);
close($fh);

my $expect = pack('la*',1110071017,'Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)');

is($robots->{cache}->{"198.76.195.159"},$expect,'Yahoo Slurp! robots.txt request');

package Handler;

sub new { bless {prev=>time,c=>0}, shift }

sub DESTROY {}
sub AUTOLOAD {
	my $self = shift;
	$self->{c}++;
	if( $self->{prev} != time ) {
		print STDERR $self->{c}, "\r";
		$self->{c} = 0;
		$self->{prev} = time;
	}
}

1;
