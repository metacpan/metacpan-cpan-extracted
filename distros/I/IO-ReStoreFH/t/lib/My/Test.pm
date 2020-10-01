use Test2::V0;
use File::Temp;
use File::Slurper;

sub read_text {
    my ( $filename ) = shift;
    File::Slurper::read_text( $filename, undef, 'auto' );
}

sub test_wfh {
    my ( $desc, $mode, $sub ) = @_;

    subtest $desc, sub {
        my $tmp1 = File::Temp->new;

        open my $fh, $mode, $tmp1
          or die "error creating fh $tmp1\n";

        my $tmp2 = File::Temp->new;

        {
            my $s = $sub->( $fh );

            open( $fh, '>', $tmp2->filename )
              or die( "error creating $tmp2\n" );

            $s->{dups}[0]{dup}->print( "during\n" );

            $fh->print( "dup\n" );
            $fh->flush;
        }

        is( read_text( $tmp1->filename ),
            "during\n", "redirect fh to file; write to original during dup" );

        is( read_text( $tmp2->filename ),
            "dup\n", "redirect fh to file; write to dup" );

        $fh->print( "after\n" );
        close( $fh );

        is( read_text( $tmp1->filename ),
            "during\nafter\n",
            "redirect fh to file; write to original post dup" );
    };
}

1;
