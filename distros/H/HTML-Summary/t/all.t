# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

require Config;
use vars qw( $loaded $ntests );

sub cat( $ ) {
    local $/ = undef;
    open( FH, shift ) or return '';
    my $text = <FH>;
    close( FH );
    return $text;
}

sub ok( $ ) {
    my $status = shift;
    print "not " unless $status;
    print "ok $ntests\n";
    $ntests++;
}

BEGIN { 
    $| = 1; 
    print "1..25\n"; 
}

END { print "not ok 1\n" unless $loaded; }

$ntests = 1;
use HTML::Summary;
use HTML::TreeBuilder;
$loaded = 1;

ok( 1 );

my $has_file_spec = do( 'File/Spec.pm' ) && import File::Spec;
for my $file ( qw( halloween euc jis sjis ) )
{
    my $path = $has_file_spec ?
        catfile( File::Spec->curdir, 'etc', "$file.html" ) :
        "./etc/$file.html"
    ;
    print STDERR "Creating abstract from $path ...\n";
    for my $length ( 50, 100, 150, 200, 250, 300 )
    {
        print STDERR "Creating abstract of length $length from $path ...\n";
        my $tree = new HTML::TreeBuilder;
        $tree->parse( cat $path );
        my $summary = ( 
            new HTML::Summary USE_META => 0, LENGTH => $length
        )->generate( $tree );
        print STDERR "$summary (", length( $summary ), ")\n";
        ok( length( $summary ) <= $length );
    }
}
