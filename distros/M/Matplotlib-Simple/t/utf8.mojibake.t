use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp;
use Encode qw(encode_utf8);

# Load your module
use_ok('Matplotlib::Simple') or BAIL_OUT("Could not load Matplotlib::Simple");

# 1. SETUP: Simulate the bug conditions.
# By explicitly encoding to utf8 here (and NOT using 'use utf8' in this script),
# we force $raw_bytes_label to be a string of raw bytes. 
# This is exactly what was causing the mojibake before your Fix 3.
my $raw_bytes_label = encode_utf8('ΔG rank');

# We need a dummy output file for the module to be happy
my $temp_out = File::Temp->new(SUFFIX => '.svg');

# 2. EXECUTE: Call plt() but tell it not to run Python
my $py_filename = plt({
    data          => {
        anomaly => {
            Prediction       => [ 1, 2, 3 ],
            $raw_bytes_label => [ 4, 5, 6 ],
        }
    },
    'plot.type'   => 'scatter',
    'output.file' => $temp_out->filename,
    execute       => 0, # CRITICAL: Do not actually run Python in a test environment
});

# 3. VERIFY: Open the generated Python file and read it as UTF-8
ok(-e $py_filename, "Python temp file was generated at $py_filename");

open my $fh, '<:encoding(UTF-8)', $py_filename 
    or die "Cannot open generated python file $py_filename: $!";
my $py_code = do { local $/; <$fh> };
close $fh;

# The correct Unicode string we expect to see inside the Python file
my $correct_unicode = 'ΔG rank';

# The dreaded mojibake (double-encoded string) we want to ensure DOES NOT exist
my $mojibake = 'ÃŽâ€';

# 4. ASSERT: Check the contents of the Python script
like(
    $py_code, 
    qr/\Q$correct_unicode\E/, 
    "The python script contains the correctly decoded UTF-8 string ('$correct_unicode')"
);

unlike(
    $py_code, 
    qr/\Q$mojibake\E/, 
    "The python script does NOT contain double-encoded mojibake"
);

done_testing();