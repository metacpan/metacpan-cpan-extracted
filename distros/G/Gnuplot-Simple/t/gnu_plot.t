use Test::More tests => 6;
use Gnuplot::Simple qw(:all);
use File::Slurper qw(read_text);
use Test::Exception;
use Cwd;
use File::Basename;

my $testdir=dirname(__FILE__);

{
    #this dataset contains some whitespace to test that case too
    my $D = [ [ 1, "3 " ], [ 2, 4 ] ];
    my $test_csv = "$testdir/gnuplot_test.csv";
    write_data( $test_csv, $D );
    is(
        read_text( $test_csv ),
        "1\t\"3 \"\n2\t4",
        'Writes gnuplot file correctly'
    );

    #test exception
    my $d = [ ['"a'] ];
    dies_ok { write_data( $test_csv, $d ) } 'Does not accept "';
    throws_ok { write_data( $test_csv, [] ) } qr/Non-empty/, 'Must contain data';
    throws_ok { write_data( $test_csv, [ [] ] ) } qr/more than one/, 'Must contain labels';

    `rm -f $test_csv`;

}

#exec_commands
{
    my $d = [ [ 1, 1 ], [ 2, 2 ], [ 3, 3 ] ];
    my $f = $testdir . "/test.png";
    exec_commands(
        qq{
        set terminal png tiny
        set output "$f"
        plot __DATA__ u 1:2 
        }, $d
    );
    ok( -e $f, 'Creates an image file' );
    `rm -f $f`;

    #test error handling
    throws_ok { exec_commands( "asdf\n", $d ) } qr/invalid command/, 'Captures gnuplot stderr.';
}
