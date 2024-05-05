#! perl

use v5.26;

use Test::More;
use JSON::Relaxed;
use JSON::PP;
use File::LoadLines;
note("JSON::Relaxed version $JSON::Relaxed::VERSION\n");
note("JSON::PP version $JSON::PP::VERSION\n");

-d "t" && chdir("t");
-d "regtests" && chdir("regtests");

my @files = sort glob("*.rjson");

my $tests = 0;
my $pp = JSON::PP->new;
my $p = JSON::Relaxed->new;
foreach my $rjsonfile ( @files ) {

    # Load the file.
    my $opts = { split => 0, fail => "soft" };
    my $rjsondata = loadlines( $rjsonfile, $opts );
    ok( $rjsondata, "$rjsonfile - load" ); $tests++;
    diag( "$rjsonfile: " . $opts->{error} ) if $opts->{error};
    next unless $rjsondata;

    # Parse it.
    my $rjsonparsed = $p->decode($rjsondata);
    ok( $rjsonparsed, "$rjsonfile - parse" ); $tests++;

    # Create the reference file if needed.
    my $jsonfile = $rjsonfile =~ s/\.rjson/.json/r;
    if ( $ENV{AUTHOR_TESTING} && ! -s $jsonfile ) {
	my $jsondata = $pp->encode($rjsonparsed);
	open( my $fd, '>:utf8', $jsonfile );
	print $fd $jsondata;
	print $fd "\n";
	ok( !close($fd), "$jsonfile  - created");
	$tests++;
    }

    # Load and parse ref data with JSON.
    $opts = { split => 0, fail => "soft" };
    my $jsondata = loadlines( $jsonfile, $opts );
    ok( $jsondata, "$jsonfile  - load" ); $tests++;
    diag( "$jsonfile: " . $opts->{error} ) if $opts->{error};
    my $jsonparsed = eval { $pp->decode($jsondata) };
    diag( "$jsonfile: $@\n") unless defined $jsonparsed;
    # Verify.
    is_deeply( $rjsonparsed, $jsonparsed, "$rjsonfile - ok"); $tests++;

    # Parse ref data with RJSON and verify.
    $rjsonparsed = $p->decode($jsondata);
    diag("$jsonfile  - " . $p->err_msg) unless $jsonparsed;
    is_deeply( $rjsonparsed, $jsonparsed, "$jsonfile  - ok"); $tests++;
}

done_testing($tests);
