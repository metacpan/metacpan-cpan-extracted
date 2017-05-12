use strict;
use warnings;

use Test::More tests => 18;

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

# Verify numeric repeats for signed char.
for ( -127, 2, 20, 127 ) {
    @items = ( -128 .. $_ );
    my $set = $_ + 129;
    $packed = pack( "c$set", @items );
    check_io( "b$set", "b$set", @items );
    is( $invindex->slurp_file("b$set"),
        $packed, "pack and lu_write handle signed bytes identically" );
}

# Verify numeric repeats for unsigned char.
for ( 2, 20, 127 ) {
    @items = ( 1 .. $_ );
    $packed = pack( "C$_", @items );
    check_io( "B$_", "B$_", @items );
    is( $invindex->slurp_file("B$_"),
        $packed, "pack and lu_write handle unsigned bytes identically" );
}

# Multiple repeats in one template.
for my $num ( 2, 19, 101 ) {
    @items = ( 1 .. $num );
    @items = (@items) x 8;
    push @items, 'foo';
    my $template = '';
    $template .= $_ . "$num " for (qw( T V b B i I Q W ));
    $template .= 'T';
    check_io( $template, $template, @items );
}

