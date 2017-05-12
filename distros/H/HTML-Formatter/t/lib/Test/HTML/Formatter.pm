package Test::HTML::Formatter;

use strict;
use warnings;
use Test::More;

sub test_files {
    my ( $test_class, %args ) = @_;

    # Pull in our class.
    my $class = 'HTML::' . $args{class_suffix};
    use_ok($class);

    # Find the files we want to test.
    foreach my $infile ( glob( File::Spec->catfile( 't', 'data', 'in', '*.html' ) ) ) {
        my $obj = new_ok($class);
        ok( -f $infile, "Testing file handling for $infile" );
        my $expfilename = ( File::Spec->splitpath($infile) )[2];
        $expfilename =~ s/\.html$/.$args{filename_extension}/i;
        my $expfile = File::Spec->catfile( 't', 'data', 'expected', $expfilename );
        ok( -f $expfile, "  Expected result file $expfile exists" );
        if ( -f $expfile ) {
            SKIP:
            {
                if ( -s $expfile == 0 ) {
                    skip "No idea what $expfile should look like", 1;
                }
                $args{callback_test_file}->( $obj, $infile, $expfile );
            }
        }
    }
}

1;
