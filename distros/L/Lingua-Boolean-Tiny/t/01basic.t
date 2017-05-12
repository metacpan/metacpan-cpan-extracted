use strict;
use warnings;
use Test::More tests => 80;

use Lingua::Boolean::Tiny;

ok boolean $_
	for qw( 1 Y y YES Yes yes OUI Oui oui JA Ja ja );

ok defined boolean($_) && !boolean($_)
	for qw( 0 N n NO No no NON Non non NEIN Nein nein );

ok !defined boolean($_)
	for qw( 666 FOOBAR Foobar foobar );

ok boolean $_, "en"
	for qw( 1 Y y YES Yes yes );

ok defined boolean($_, "en") && !boolean($_, "en")
	for qw( 0 N n NO No no );

ok !defined boolean($_, "en")
	for qw( 666 FOOBAR Foobar foobar OUI Oui oui JA Ja ja NON Non non NEIN Nein nein );

ok boolean $_, ["en", "fr"]
	for qw( 1 Y y YES Yes yes OUI Oui oui );

ok defined boolean($_, ["en", "fr"]) && !boolean($_, ["en", "fr"])
	for qw( 0 N n NO No no NON Non non );

ok !defined boolean($_, ["en", "fr"])
	for qw( 666 FOOBAR Foobar foobar );

my $fr = Lingua::Boolean::Tiny->new("fr");
is($fr->yesno(1), 'oui');
is($fr->yesno(0), 'non');
