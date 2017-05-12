use strict;
use warnings;

use Test::More;

use Getopt::Mini later=>1;

{
    my %args = getopt( argv=>[ '-data', '99', '--foo', '11', '-foo', 22 ] );
    is $args{data}, 99, 'first arg';
    is join( ' ',@{$args{foo}} ), '11 22', 'push args';
}

{
    my %args = getopt( argv=>[ '-d', '11', '22', '-h', '--foo', 22, '-d' ] );
    ok exists( $args{d} ), 'defined arg doesnt eat bareword';
    is join(' ',@{$args{''}}), '11 22', 'bare middle';
}
{
    my %args = getopt( argv=>[ 'loose', '-d', '-f' ] );
    ok exists( $args{d} ), 'defined arg';
    ok grep( /loose/, $args{''} ), 'bareword';
}

done_testing;
