# t/fit2tcx.t - script to convert FIT files to TCX 
use Test::More tests => 5;

use strict;
use warnings;
use Geo::FIT;
use File::Temp qw/ tempfile /;
use IPC::System::Simple qw(capture run EXIT_ANY );

# variables we need
my ($input_file, $output_file, $at_least_version);
$input_file = 't/10004793344_ACTIVITY.fit';
($output_file = $input_file) =~ s/\.fit$/.tcx/;
$at_least_version = '1.03';              # arbitrary number, just to check if we can check

#
# Look-up the script's --version (testing look-up works)

#   - use backticks to capture output or IPC::System::Simple's capture()
#   - run() does not capture output but allows for checking the exit status if needed
#   - run() is an alias for system() as per the IPS:System::Simple pod
#   - $^X is the full path to perl interpreter that called this test file

# my $captured_out = `$^X script/fit2tcx.pl --version`;
my $captured_out = capture($^X, 'script/fit2tcx.pl', '--version');
my ( $version_msg, $version_num) = split /: (?=\d+\.\d+$)/, $captured_out;
is( $version_num >= $at_least_version, 1,   "    fit2tcx.pl: can we look up the script's version?");

#
# A - Can the sript be found in the $PATH?

#   - this will be moved to t/fit.t in Geo::TCX
#   - testing here for convenience and ensure it works on various platforms before moving to Geo::TCX

my $captured_stat;
# $captured_stat = run(EXIT_ANY, 'fit2tcx.pl', '--version');
eval { $captured_stat = run([0], 'fit2tcx.pl', '--version'); };

my $has_a_version_installed;
if ($@ =~ /failed to start: "(.*)"/ ) {
    my $reason    = $!;             # in case we need it
    my $shell_msg = $1;             # in case we need it
    $has_a_version_installed = 0
} elsif (defined $captured_stat && $captured_stat == 0) {
    $has_a_version_installed = 1
}
# } else {
#    die "Something else happened: $@\n"
# }
# condition for author above (for debugging)
#  - users may have installed an earlier version that not have the --version option yet
#  - in which case the run() would return 255
#  - so don't die() for that, they need to be able to upgrade!

#
# B - Get which version is installed if any

my $version_num_installed;
if ($has_a_version_installed) {
    my $captured_out = capture($^X, 'script/fit2tcx.pl', '--version');
    ($version_msg, $version_num_installed) = split /: (?=\d+\.\d+$)/, $captured_out;
}

# Once blocks A and B above are robust enough we will
#   1. move blocks A and B to Geo::TCX t/fit.t
#   2. skill all tests in t/fit.t unless $has_a_version_installed is true (could also skip if $version_num_installed is not high enough)
#   3. modify _convert_fit_to_tcx to croak if the script is not found and also store the version number of the script
#       - in case we need to require a minimum version number later at some point

#
# convert a FIT file

my @args = ('--indent=4', $input_file, $output_file );
run($^X, 'script/fit2tcx.pl', @args);
is(-f $output_file, 1, "    fit2tcx.pl: results in new tcx file");
unlink $output_file;

# 
# convert a FIT file to a temporary file

my ($fh, $tmp_fname) = tempfile();
# may have to add option --force once it is added to the script
@args = ('--indent=4', $input_file, $tmp_fname );
run($^X, 'script/fit2tcx.pl', @args);
is(-f $tmp_fname, 1, "    fit2tcx.pl: results in new temporary file");

#
# convert a file that is not a FIT file -- expect failure

#  - case 1) already a *.tcx
@args = ('--indent=4', $output_file, 'foo.fit' );    # $output_file from above becomes the input_file
eval { run($^X, 'script/fit2tcx.pl', @args) };
is( $IPC::System::Simple::EXITVAL, 255, "    fit2tcx.pl: skip converting file that is already a *.tcx file");
is(-f 'foo.fit', undef,                 "    fit2tcx.pl: does NOT result in new FIT file");

#  - case 2) neither a *.tcx nor a FIT file --  will fail at fetch_header()
#  TODO: test case 2)

unlink $output_file;

print "so debugger doesn't exit\n";

