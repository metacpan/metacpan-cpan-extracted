#! perl

use strict;
use warnings;
use utf8;

-d 't' && chdir 't';

use Test::More tests => 2;
BEGIN { use_ok('HarfBuzz::Shaper') };

my $hb = HarfBuzz::Shaper->new;

$hb->set_font('LiberationSans.ttf');
$hb->set_size(36);
$hb->set_text("Hell€!");
my $info = $hb->shaper;

my $result = [
  {
    ax => '25.992',
    ay => 0,
    dx => 0,
    dy => 0,
    g => 4,
    name => 'H',
  },
  {
    ax => '20.016',
    ay => 0,
    dx => 0,
    dy => 0,
    g => 5,
    name => 'e',
  },
  {
    ax => '7.992',
    ay => 0,
    dx => 0,
    dy => 0,
    g => 6,
    name => 'l',
  },
  {
    ax => '7.992',
    ay => 0,
    dx => 0,
    dy => 0,
    g => 6,
    name => 'l',
  },
  {
    ax => '20.016',
    ay => 0,
    dx => 0,
    dy => 0,
    g => 8,
    name => 'Euro',
  },
  {
#    ax => '10.008',		# harfbuzz 1.8.7
    ax => '9.972',		# harfbuzz 2.6.4
    ay => 0,
    dx => 0,
    dy => 0,
    g => 3,
    name => 'exclam',
  },
];

ok(compare( $info, $result ), "content" );

sub compare {
    my ( $soll, $ist ) = @_;
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
	unless ( $i->{name} eq $j->{name} ) {
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
