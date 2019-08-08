use t::lib::Test;

use JSON::MaybeXS qw(encode_json   decode_json);
use File::Temp    qw(tempdir);

my $dir;
BEGIN {
    $dir = tempdir( "quickcover-test-XXXX", TMPDIR => 1);
    require Devel::QuickCover;
    Devel::QuickCover->import(nostart=>1, nodump=>1, output_directory=>$dir);
}

my $x=1;
Devel::QuickCover::start();
my $y=2;                   # __YES__
Devel::QuickCover::end();  # __YES__
my $z=3;

my ($report_fname, $report) = read_report($dir)
    or fail 'No report file generated';

my $got      = get_coverage_from_report(__FILE__, $report);
my $expected = parse_fixture(__FILE__);

#use Data::Dumper;
#warn Dumper $report;
delete $report->{files}->{+__FILE__}->{phases};

is_deeply($got, $expected, "Report only contains the half-open interval ]start(), end()]");

done_testing;

