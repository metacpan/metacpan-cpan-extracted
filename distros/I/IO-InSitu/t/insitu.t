use IO::InSitu;
use Test::More 'no_plan';

my $orig_data = <<'END_DATA';
original data
END_DATA

ok open(my $fh, '>datafile') => 'Opening data file';
ok print($fh $orig_data)     => 'Populating data file';
ok close($fh)                => 'Closing data file';

my ($infile, $outfile) = open_rw('datafile', 'datafile');
my $readdata = do { local $/; <$infile> };

is $readdata, $orig_data     => 'Read works';

$readdata  =~ s/original/new/;
$orig_data =~ s/original/new/;

ok print($outfile $readdata) => 'Writing back possible';

ok close($outfile)           => 'Output handle closed';

ok open($fh, '<datafile')    => 'Opening data file again';

$readdata = do { local $/; <$fh> };

is $readdata, $orig_data     => 'Writing back works';

ok -e 'datafile.bak'         => 'Verifying backup file created';

ok unlink('datafile')        => 'Cleaning up data file';

ok close($infile)            => 'Closing input handle';
$infile = undef;

ok !-e 'datafile.bak'        => 'Verifying backup file removed';
