use strict;
use warnings;
use Digest::MD5 qw/md5_hex/;

use Test::More tests => 2;

use FindBin qw/$RealBin/;
use lib "$RealBin/../lib";
use_ok 'File::Generator';

# Because we have to control for randomness in these tests,
# set an explicit seed.
srand(42);
my $generator = File::Generator->new();

subtest "Create random fastq files and hashsum them" => sub {
  my $numtests=5;
  plan tests => $numtests;
  # Up to 10 tests that we can choose to do
  my @hashsum=('960d42bc1db5f80ad17895813059b7db', '3d87d52e5f2bba11ff92e0248a1657a7', 'a199517f5212969e1a5db5c814dca7e5', '225228345feffb5d4df0881a4c35b57a', '89ffb9187fd22bf443811af21ec25f3d', 'b6056fc8955576aaad473c363985c7c4', 'af73963493ef84c6bd92da7945f10ee8', 'afed23cef835f86d9c0ec3b703d78a81', '6d922bc7e025a60ae7ee7376574c2b95', '4ec072c30cb230586b8d38723a401550');
  for(my $i=0;$i<$numtests;$i++){
    my $j=$i+1;
    my $fastqFile = $generator->generate("fastq");
    is hashsumFile($fastqFile), $hashsum[$i], "Test random file $j";
  }
  close MATRIX;
};

# Sub to emulate md5sum
sub hashsumFile{
  my($file)=@_;
  my $content;
  open(my $fh, $file) or die "ERROR reading $file: $!";
  while(<$fh>){
    $content.=$_;
  }
  close $fh;
  
  return md5_hex($content);
}
