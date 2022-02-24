use Modern::Perl;
use HackaMol;
use Sereal::Encoder qw(sereal_encode_with_object);
use Sereal::Decoder
  qw(sereal_decode_with_object);
use Time::HiRes qw(time);
use Path::Tiny;

my $t1 = time;
my $mol = HackaMol->new->pdbid_mol('2cba');
my $t2 = time;
printf ("read: %10.2f\n", $t2 - $t1);

my $encoder = Sereal::Encoder->new; #({...options...});
#my $out = $encoder->encode($mole);

my $test = sereal_encode_with_object($encoder, $mol);
my $t3 = time;

printf ("encode: %10.2f\n", $t3 - $t2);
path('test.sereal')->spew($test);
my $t4 = time;
printf ("write file: %10.4f\n", $t4 - $t3);

my $read = path('test.sereal')->slurp;

my $t5 = time;
printf ("read file: %10.4f\n", $t5 - $t4);

my $decoder = Sereal::Decoder->new;
my $mol2 = $decoder->decode($read);
my $t6 = time;

#$test2->print_pdb;
printf ("decode: %10.4f\n", $t6 - $t5);

say $mol->COM;
say $mol2->COM;

#my $test2 = sereal_decode_with_object($test);
#my $decoder = Sereal::Decoder->new({...options...}); 
#my $structure;
#$decoder->decode($blob, $structure); 

