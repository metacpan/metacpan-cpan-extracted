
use strict;
use Test;
use File::Spec;
BEGIN { plan tests => 4 };
use File::NCopy 0.35;
ok(1); # Loaded

# New object
my $test = File::NCopy->new(test => 1);
ok($test);

# Need this later
my $dirsep = File::Spec->catfile('a','b');
$dirsep =~ s!a(.+)b$!$1!;
my $rdirsep = ($dirsep eq '\\' ? '\\\\' : $dirsep );

# Test Defaults
ok($test->{recursive} == 0 && $test->{preserve} == 0 && $test->{follow_links} == 0 && $test->{force_write} == 0);

my $tmp_dir = File::Spec->tmpdir();
my $path = File::Spec->catfile($tmp_dir,'test_ncpy_inst');
mkdir $path,0777 unless (-e $path); #perl 5.5 requires both arguments to mkdir
$test->{recursive} = 1;
my @files = $test->copy($tmp_dir,$path);
if ((scalar(@files) == 0)) {
    # Skip, no files to test with
    skip(1,0);
} else {
    my $done = 0;
    foreach my $path (@files) {
		# Remove a leading one, if it has it
		if (index($path,$dirsep) == 0) {
			$path = substr($path,(length($path) - length($path) - 1),(length($path) - 1));
		}
        my @parts = split(/$rdirsep/,$path);
        if (@parts > 0) {
            # it should contain a seperator
            $done = 1;
            if (index($path,$dirsep)) {
                # it has some in it.
                ok(1);
                $done = 1;
            } else {
                # this is bad.
				warn "Path '$path' (".scalar(@parts)." parts) did not contain a separator\n";
                ok(0);
                $done = 1;
            }
        } else {
            # no seperator, try next one;
            next;
        }
        if ($done) {
            last;
        }
    }
    if (! $done) {
        ok(0);
    }
}
