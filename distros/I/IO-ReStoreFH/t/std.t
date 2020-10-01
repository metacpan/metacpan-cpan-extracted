#!perl

use Test2::V0;
use File::Temp;
use Test::Lib;
use My::Test;

use IO::ReStoreFH;
use IO::Handle;

for my $fh ( \*STDOUT, *STDERR ) {

    my $tmp = File::Temp->new;

    {
        my $s = IO::ReStoreFH->new( $fh );

        open( $fh, '>', $tmp->filename )
          or die( "error creating $tmp\n" );

        $fh->print( "$fh\n" );
    }

    is( read_text( $tmp->filename ),
        "$fh\n", "redirect $fh to file; implicit close" );
}

done_testing;
