# -*- cperl -*-

use utf8;

use Test::More tests => 1 + 14;

BEGIN { use_ok( 'Lingua::PT::PLNbase' ); }

  my @ss = frases(<<"EOT");
O dr. João Ratão comeu a D. Carochinha.
O Eng. visitou a av. do Marquês.
O Ex. Sr. António foi prof. de Matemática.
O Pe. Joaquim casou o Arq. João com a Profª. Joana.
Os profs. vão ao lg. do Paço.
Os profs. vão ao lgo. do Paço.
As profas. também vão ao lgo. do Paço.
No séc. V A.C. já não existiam dinossauros.
Os Exmos. Srs. deputados que...
Os Exmos. Srs. Drs. vão almoçar ao Snack-Bar.
Na rua Cel. António virar à esquerda, pela avenida do Sen. Joaquim.
A empresa de Marco Correia e Cia. Lda. fica na Trv. Mário Soares.
Foi nos E.U.A. que se assaltou qq coisa.
Por ex. Satre afirmava
EOT

  my $i = 0;
  my @sts = (q/O dr. João Ratão comeu a D. Carochinha./,
	     q/O Eng. visitou a av. do Marquês./,
	     q/O Ex. Sr. António foi prof. de Matemática./,
	     q/O Pe. Joaquim casou o Arq. João com a Profª. Joana./,
	     q/Os profs. vão ao lg. do Paço./,
	     q/Os profs. vão ao lgo. do Paço./,
	     q/As profas. também vão ao lgo. do Paço./,
	     q/No séc. V A.C. já não existiam dinossauros./,
	     q/Os Exmos. Srs. deputados que.../,
	     q/Os Exmos. Srs. Drs. vão almoçar ao Snack-Bar./,
	     q/Na rua Cel. António virar à esquerda, pela avenida do Sen. Joaquim./,
	     q/A empresa de Marco Correia e Cia. Lda. fica na Trv. Mário Soares./,
	     q/Foi nos E.U.A. que se assaltou qq coisa./,
	     q/Por ex. Satre afirmava/,
	  );

  for (@sts) {
    is(trim($ss[$i++]),$_)
  }


##------
sub trim {
  my $x = shift;
  $x =~ s/^[\n\s]*//;
  $x =~ s![\n\s]*$!!;
  $x
}
