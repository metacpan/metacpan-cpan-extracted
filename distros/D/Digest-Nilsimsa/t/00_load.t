# this can also be run from parent dir by
# perl -Iblib/lib -Iblib/arch/auto/Digest/Nilsimsa t/00_load.t

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Digest::Nilsimsa;
$loaded = 1;
print "ok 1\n";

my $n = new Digest::Nilsimsa;
print $n->testxs('iamchad') eq 'amchad' ? "" : "not ", "ok 2\n";

my $text = "chad #1";
my $digest = $n->text2digest($text);
#print STDERR "\ndigest('". $text ."'): $digest\n";
print "not " unless (defined($digest) && $digest eq "0120010810080004004122001200a8000a000020810000000000c00310400000");
print "ok 3\n";

# tests 4..7 are read from files
# if filename does not have absolute path, relative to the t/ directory
#
# NOTE: if different files have same key, only one will be in hash table
#
my %files = qw(
3c000981d4c41101baca8811b1b212031504b0819488a30402d02a201c72a408 a.txt
7fb4e5880370384c220298c94f844b35058e3c734920454765508bb57630e3ee b.txt
7fb0e5a89251884cb15218b19f841731448f7d33593046442f308b10f630716e d.txt
340e20024f758264538a09024200d8a24004940439015a1a04500a2042a24120 chad.jpg
);
my $skip = "
";

my $ok=4;
foreach (sort {$files{$a} cmp $files{$b}} keys %files) {
  my $fn = $files{$_};
  $fn = "t/$fn" unless ($fn =~ /^\//);
  open(INF,$fn) or die "\ncan't find $fn\n";
  my $text = join '', <INF>;
  close INF;
    $digest = $n->text2digest($text);
#print STDERR "\ndigest($fn): $digest\n";
#print STDERR "\ndigest($fn) errmsg: ". $n->errmsg() ."\n";
#  print "$fn \t\t";
  print "not " unless (defined($digest) && $digest eq $_);
  print "ok $ok $fn\n";
  $ok++;
}

print "Done.\n\n";
