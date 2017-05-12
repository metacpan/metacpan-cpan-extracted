# Version-control-like changes summary

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
my $dir = 't03';
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
  # Remove initial stems
  my ($a1) = ($a =~ m!^$dir/(?:old|new)/(.*)!) if $a;
  my ($b1) = ($b =~ m!^$dir/(?:old|new)/(.*)!) if $b;
  if (! $b) {
    push @results, "D   $a1\n";
  } elsif (! $a) {
    push @results, "A   $b1\n";
  } else {
    if (-f $a && -f $b) {
      push @results, "M   $b1\n";
    } else {
      push @results, "D   $a1\n";
      push @results, "A   $b1\n";
    }
  }
});

is(join('', @results), $result{changes}, "changes okay");

