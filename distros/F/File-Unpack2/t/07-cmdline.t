#!perl

use Test::More tests => 4;
use FindBin;
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };
use File::Temp;
use JSON;
$ENV{PATH} = "/bin:/usr/bin";
delete $ENV{ENV};

my $testdir = File::Temp::tempdir("FU_06_XXXXX", TMPDIR => 1, CLEANUP => 1);
my $cmd1 = "$^X ./file_unpack2 -q -L $testdir.log  -D $testdir t/data";
my $cmd2 = "$^X ./file_unpack2 -q -L $testdir.log2 -D $testdir $testdir";
my $r1 = system($cmd1);
my $r2 = system($cmd2);
ok($r1 == 0, "normal: $cmd1");
ok($r2 == 0, "inplace: $cmd2");

open IN, "<", "$testdir.log"; 
my $log1 = JSON::from_json(join '', <IN>); 
close IN;
open IN, "<", "$testdir.log2"; 
my $log2 = JSON::from_json(join '', <IN>); 
close IN;

# check if all files from data reappear in the log.
my %missing;
opendir DIR, "t/data";
while (my $f = readdir DIR)
  {
    next if $f =~ m{^\.};
    next if $log1->{unpacked}{$f};
    my $ff = "$log1->{input}/$f";
    next if $log1->{unpacked}{$ff} and $log1->{unpacked}{$ff}{unpacked};
      
    $missing{$f} = 1;

    # search, in case it was 'passed' with a different name.
    for my $u (values %{$log1->{unpacked}})
      {
        # happens with bad34.pdf
        delete $missing{$f} if $u->{passed} and $u->{input}||'' eq $ff;
      }
  }
closedir DIR;
if (exists $missing{'pdftex-a.txt'}) 
  {
    delete $missing{'pdftex-a.txt'};
    warn "known bug: missing file after helper failure: pdftex-a.txt\n";
  }
my @missing = keys %missing;
ok($#missing < 0, "all input files appear in logfile");
if ($#missing >= 0)
  {
    use Data::Dumper;
    warn Dumper ["missing: ", \@missing, $log1];
  }
 
@missing = ();
# check if all files in the new log have already been in the old log.
for my $f (keys %{$log2->{unpacked}})
  {
    next if $log1->{unpacked}{$f};
    push @missing, $f;
  }
ok($#missing < 0, "all files from recreated log were there before");
if ($#missing >= 0)
  {
    use Data::Dumper;
    warn Dumper ["missing: ", \@missing, $log1, $log2];
  }
unlink "$testdir.log";
unlink "$testdir.log2";
