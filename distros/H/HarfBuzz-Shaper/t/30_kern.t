#! perl

use strict;
use warnings;
use utf8;

-d 't' && chdir 't';

use Test::More tests => 4;
BEGIN { use_ok('HarfBuzz::Shaper') };

my $hb = HarfBuzz::Shaper->new;

$hb->set_font('NimbusRoman-Regular.otf');
$hb->set_size(36);
$hb->set_text("LVAT");
my $info = $hb->shaper;
#use DDumper; DDumper($info);
my $result = [
  { ax => '17.856', ay => 0, dx => 0, dy => 0, g => 45, name => 'L' },
  { ax => '21.672', ay => 0, dx => 0, dy => 0, g => 55, name => 'V' },
  { ax => '24.048', ay => 0, dx => 0, dy => 0, g => 34, name => 'A' },
  { ax => '21.996', ay => 0, dx => 0, dy => 0, g => 53, name => 'T' },
];

ok(compare( $info, $result ), "content default kern" );

$hb->set_features( 'kern=1' );
$info = $hb->shaper;

ok(compare( $info, $result ), "content +kern feature" );

$info = $hb->shaper( [ '-kern' ] );

$result = [
  { ax => '21.996', ay => 0, dx => 0, dy => 0, g => 45, name => 'L' },
  { ax => '25.992', ay => 0, dx => 0, dy => 0, g => 55, name => 'V' },
  { ax => '25.992', ay => 0, dx => 0, dy => 0, g => 34, name => 'A' },
  { ax => '21.996', ay => 0, dx => 0, dy => 0, g => 53, name => 'T' },
];

ok(compare( $info, $result ), "content -kern feature" );

sub compare {
    my ( $ist, $soll ) = @_;
    unless ( @$ist == @$soll ) {
	diag( scalar(@$ist) . " elements, must be " . scalar(@$soll) );
	return;
    }

    for ( 0 .. @$ist-1 ) {
	my $i = $ist->[$_];
	my $j = $soll->[$_];
	unless ( $i->{g} == $j->{g} ) {
	    diag( "CId $i->{g} must be $j->{g}" );
	    return;
	}
	unless ( $i->{name} eq $j->{name} or $i->{name} eq '' ) {
	    diag( "Name $i->{name} must be $j->{name}" );
	    return;
	}
	for ( qw( ax ay dx dy ) ) {
	    next if $i->{$_} == $j->{$_};
	    unless ( abs( $i->{$_} - $j->{$_} ) <= abs($j->{$_} / 100) ) {
		diag( "$_ $i->{$_} must be $j->{$_}" );
		return;
	    }
	}
    }
    return 1;
}
