use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use IO::File;
use Test::More;
use JavaScript::Minifier::XS qw(minify);

###############################################################################
# figure out how many JS files we're going to run through for testing
my @files = <t/js/*.js>;
plan tests => scalar @files;

###############################################################################
# test each of the JS files in turn
foreach my $file (@files) {
    (my $min_file = $file) =~ s/\.js$/\.min/;
    my $str = slurp( $file );
    my $min = slurp( $min_file );
    my $res = eval { minify( $str ) };

    is( $res, $min, $file ) or diag ($@);
}





###############################################################################
# HELPER METHOD: slurp in contents of file to scalar.
###############################################################################
sub slurp {
    my $filename = shift;
    my $fin = IO::File->new( $filename, '<' ) || die "can't open '$filename'; $!";
    my $str = join('', <$fin>);
    $fin->close();
    chomp( $str );
    return $str;
}
