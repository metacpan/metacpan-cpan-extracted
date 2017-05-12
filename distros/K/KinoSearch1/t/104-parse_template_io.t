use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok('KinoSearch1::Store::RAMInvIndex');
}

my $invindex = KinoSearch1::Store::RAMInvIndex->new;
my ( @items, $packed, $template );

sub check_io {
    my ( $filename, $tpt ) = ( shift, shift );
    my $outstream = $invindex->open_outstream($filename);
    $outstream->lu_write( $tpt, @_ );
    $outstream->close;
    my $instream = $invindex->open_instream($filename);
    my @got      = $instream->lu_read($tpt);
    is_deeply( \@got, \@_, $filename );
}

my $outstream = $invindex->open_outstream("fake_file");
eval { $outstream->lu_write( 'u', 'foo' ); };
like( $@, qr/illegal character/i, "Illegal symbol in template caught" );

@items = qw( foo bar );
check_io( "leading and trailing whitespace", "    T    T   ", @items );

@items = ( qw( foo bar baz ), 0 .. 5 );
$template = "TT2Ti3Qb";
check_io( "Tightly packed template", $template, @items );
