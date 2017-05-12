use Test::More;

BEGIN {
    use_ok( 'HTML::Barcode' ) || print "Bail out!
";
}

diag( "Testing HTML::Barcode $HTML::Barcode::VERSION, Perl $], $^X" );

done_testing;
