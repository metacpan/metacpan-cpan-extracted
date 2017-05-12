use v5.20;
use warnings;
use strict;
use Data::Dumper;
##use Devel::Peek 'Dump';
#
use Test::More qw(no_plan);
#
BEGIN {
	use_ok( 'FreeBSD::FsStat' );
}

my $a = FreeBSD::FsStat::getfsstat();
is( ref( $a ) , 'ARRAY', 'getfsstat returns array reference' ) ;
#
#
# say STDERR Dumper( $a );
my @b = FreeBSD::FsStat::get_filesystems;

for (@b) {
	isa_ok( $_ , 'FreeBSD::FileSystem' );
}

#say Dumper( \@b );
#
#say $b[0]->size;
#say $b[0]->free;
#say $b[0]->avail;
#say $b[0]->pct_free;
#say $b[0]->pct_avail;
