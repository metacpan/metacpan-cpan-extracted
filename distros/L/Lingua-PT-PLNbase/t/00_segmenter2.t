# -*- cperl -*-

use Test::More tests => 1 + 14;

use POSIX qw(locale_h);
setlocale(LC_CTYPE, "pt_PT");
use locale;

BEGIN { use_ok( 'Lingua::PT::PLNbase' ); }


$a = '«·È';

SKIP: {
  skip "not a good locale", 14 unless $a =~ m!^\w{3}$!;


  my @ss = frases(<<"EOT");
O dr. Jo„o Rat„o comeu a D. Carochinha.
O Eng. visitou a av. do MarquÍs.
O Ex. Sr. AntÛnio foi prof. de Matem·tica.
O Pe. Joaquim casou o Arq. Jo„o com a Prof™. Joana.
Os profs. v„o ao lg. do PaÁo.
Os profs. v„o ao lgo. do PaÁo.
As profas. tambÈm v„o ao lgo. do PaÁo.
No sÈc. V A.C. j· n„o existiam dinossauros.
Os Exmos. Srs. deputados que...
Os Exmos. Srs. Drs. v„o almoÁar ao Snack-Bar.
Na rua Cel. AntÛnio virar ‡ esquerda, pela avenida do Sen. Joaquim.
A empresa de Marco Correia e Cia. Lda. fica na Trv. M·rio Soares.
Foi nos E.U.A. que se assaltou qq coisa.
Por ex. Satre afirmava
EOT

  my $i = 0;
  my @sts = (q/O dr. Jo„o Rat„o comeu a D. Carochinha./,
	     q/O Eng. visitou a av. do MarquÍs./,
	     q/O Ex. Sr. AntÛnio foi prof. de Matem·tica./,
	     q/O Pe. Joaquim casou o Arq. Jo„o com a Prof™. Joana./,
	     q/Os profs. v„o ao lg. do PaÁo./,
	     q/Os profs. v„o ao lgo. do PaÁo./,
	     q/As profas. tambÈm v„o ao lgo. do PaÁo./,
	     q/No sÈc. V A.C. j· n„o existiam dinossauros./,
	     q/Os Exmos. Srs. deputados que.../,
	     q/Os Exmos. Srs. Drs. v„o almoÁar ao Snack-Bar./,
	     q/Na rua Cel. AntÛnio virar ‡ esquerda, pela avenida do Sen. Joaquim./,
	     q/A empresa de Marco Correia e Cia. Lda. fica na Trv. M·rio Soares./,
	     q/Foi nos E.U.A. que se assaltou qq coisa./,
	     q/Por ex. Satre afirmava/,
	  );

  for (@sts) {
    is(trim($ss[$i++]),$_)
  }
}


##------
sub trim {
  my $x = shift;
  $x =~ s/^[\n\s]*//;
  $x =~ s![\n\s]*$!!;
  $x
}
