# -*- cperl -*-

use Test::More tests => 11;

use POSIX qw/locale_h/;
setlocale(LC_CTYPE, "pt_PT");
use locale;
use Data::Dumper;
use Lingua::PT::ProperNames;

$a = 'à';

SKIP: {
  skip "not a good locale", 11 unless $a =~ m!^\w$!;

  my $count=0;
  my %pnlist=();
  my $countD=0;
  my %pnlistD=();

  forPN({in=>"t/01.forPN.input"},
	sub{$pnlist{n($_[0])}++; $count++});

  is( $count, "326", "Total number of ProperNames detected");

  is_count( "Portugal"         , 5);
  is_count( "Pimenta Machado"  , 4);
  is_count( "Ribeiro da Silva" , 1);
  is_count( "Espanha" , 1);

  ### franceses:
  is_count( "Dias d'Almeida",1);
  is_count( "Josquin des Prais",1);
  is_count( "Cirille du Val",1);
  is_count( "Marie de la Caaaaa",1);

  my $out = forPN("Eu vi França e Espanha",
	sub{$pnlist{n($_[0])}++; $count++;"==$_[0]==" });
  is_count( "Espanha" , 2);
  is("Eu vi ==França== e ==Espanha==",$out);

  sub is_count {
    my ($word, $count) = @_;
    is($pnlist{$word}, $count, $word);
  }

  sub n{
    my $a=shift;
    for($a){s/\s+/ /g; s/^ //; s/ $//;}
    $a;
  }
}
1;



