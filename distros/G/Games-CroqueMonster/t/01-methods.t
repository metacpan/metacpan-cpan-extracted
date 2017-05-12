#!perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'Games::CroqueMonster' );
}

my $cm = new Games::CroqueMonster ;
ok($cm);
my $agency = $cm->agency('UglyBeasts');
ok( $agency->{agency}->{id} == 383869);
my $items = $cm->items();
ok( defined($items->{items}->{item}->{0}->{id}) && defined($items->{items}->{item}->{0}->{name}) && defined($items->{items}->{item}->{0}->{image}) );
my $syndicate = $cm->syndicate('Tenebrae');
ok($syndicate->{syndicate}->{id} == 1802);
