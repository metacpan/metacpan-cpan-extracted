use strict;
use warnings;

use Test::More tests => 5;

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

my @chars = ( qw( a b c d 1 ), "\n", "\0", " ", " ", "\xf0\x9d\x84\x9e" );

for ( 0, 22, 300 ) {
    @items = ( 'a' x $_ );
    check_io( "string of length $_", 'T', @items );
}

{
    @items = ();
    for ( 1 .. 50 ) {
        my $string_len = int( rand() * 5 );
        my $str        = '';
        $str .= $chars[ rand @chars ] for 1 .. $string_len;
        push @items, $str;
    }
    check_io( "50 strings", "T50", @items );
}

