use Modern::Perl;
use HackaMol;
use Sereal::Encoder qw(sereal_encode_with_object);
use Sereal::Decoder
  qw(sereal_decode_with_object);
use Time::HiRes qw(time);

my $t1 = time;
my $mol = HackaMol->new->pdbid_mol('2cba');
my $t2 = time;
printf ("read: %10.2f\n", $t2 - $t1);

my $encoder = Sereal::Encoder->new; #({...options...});
#my $out = $encoder->encode($mole);

my $shit = sereal_encode_with_object($encoder, $mol);
my $t3 = time;

printf ("encode: %10.2f\n", $t3 - $t2);

my $shit2;
my $decoder = Sereal::Decoder->new;
$decoder->decode($shit, $shit2);
my $t4 = time;

#$shit2->print_pdb;
printf ("decode: %10.2f\n", $t4 - $t3);

#my $shit2 = sereal_decode_with_object($shit);
#my $decoder = Sereal::Decoder->new({...options...}); 
#my $structure;
#$decoder->decode($blob, $structure); 

