# 'cmp' option test

my $num_tests;
BEGIN { $num_tests = 2 };

use strict;
use Test::More tests => $num_tests;
use File::Basename;
use File::Spec::Functions;
BEGIN { use_ok('File::DirCompare') };

chdir dirname($0) or die "can't chdir to " . dirname($0);

# Load result strings
my %result = ();
my $dir = 't06';
my $results_dir = File::Spec->catfile($dir, 'results');
die "missing data dir $dir" unless -d $dir;
die "missing results dir $results_dir" unless -d $results_dir;
opendir DATADIR, $results_dir or die "can't open directory $results_dir";
for (readdir DATADIR) {
  next if m/^\./;
  next if m/^=/;
  open FILE, "<$results_dir/$_" or die "can't read $results_dir/$_";
  { 
    local $/ = undef;
    $result{$_} = <FILE>;
  }
  close FILE;
}
close DATADIR;

my @results;

File::DirCompare->compare(catfile($dir,'old'), catfile($dir,'new'), sub {
  my ($a, $b) = @_;
  return if $a && $a =~ m/\.arch-ids/ or $b && $b =~ m/\.arch-ids/;
  if ($a && $b) {
    push @results, "Files $a and $b differ\n";
  }
}, { cmp => sub { ! File::Compare::compare(@_) } });

is(join('', @results), $result{cmp}, 'cmp ok');

