#!perl

use IO::ReStoreFH;

use IO::Handle;

use Test::More;
use Test::File::Contents;

use File::Temp;

for my $fh ( \*STDOUT, *STDERR ) {

    my $tmp = File::Temp->new;

    {
        my $s = IO::ReStoreFH->new( $fh );

        open( $fh, '>', $tmp->filename )
          or die( "error creating $tmp\n" );

        $fh->print( "$fh\n" );
    }

    file_contents_eq_or_diff( $tmp->filename, "$fh\n",
        "redirect $fh to file; implicit close" );
}


done_testing;
