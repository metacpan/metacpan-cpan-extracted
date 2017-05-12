use Test;
BEGIN { plan tests => 2 };
use Devel::TrackObjects 'track_object','-noend';

package A;
sub new { return bless {},shift }

package main;
my $x = A->new;
track_object($x,'whatever');
my $y = A->new; # don't track

$o = Devel::TrackObjects->show_tracked;
ok( $o->{A} == 1 );

if ( $] >= 5.008 ) {
	my $buf;
	{
		local *STDERR;
		open( STDERR,'>',\$buf );
		Devel::TrackObjects->show_tracked_detailed;
	}
	ok( $buf =~m{^-- A=HASH\(0x\w+\).* whatever}m );
} else {
	ok( 'old perl dummy' ); # not available in older perl
}


