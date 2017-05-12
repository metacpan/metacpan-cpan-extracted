use t::lib::Test;

use File::Temp  qw(tempdir);

my $FIXTURES = './fixtures';
my $dir      = tempdir( "quickcover-test-XXXX", TMPDIR => 1);

sub test_fixture {
    my $file = shift;
    my @cmd = (
        $^X,
        '-I./blib/lib',
        '-I./blib/arch/',
        "-MDevel::QuickCover=output_directory,$dir",
        $file,
    );
    system( @cmd );

    my ($report_fname, $report) = read_report( $dir )
        or fail "Got report after execution for $file";

    my $got      = get_coverage_from_report( $file, $report );
    my $expected = parse_fixture( $file );

    #use Data::Dumper;
    #warn Dumper $report;
    delete $report->{files}->{$file}->{phases};

    is_deeply( $got, $expected, "Got what we expected from the report for $file" );

    $report_fname
        and unlink $report_fname;
}

for my $file (glob "$FIXTURES/*.pl") {
    next if $file eq "$FIXTURES/cover-05.pl" && $] lt '5.018000';
    test_fixture($file);
}

done_testing;
