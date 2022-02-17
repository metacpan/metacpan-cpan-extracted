package Lingua::PT::PLNbase;

use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Lingua::PT::Abbrev;

require Exporter;
our @ISA = qw(Exporter);

#use POSIX qw(locale_h);
#my $llang = setlocale(LC_CTYPE, "pt_PT");
#$llang    = setlocale(LC_CTYPE, "pt_BR") unless $llang;
#use locale;

use utf8;


=encoding UTF-8

=head1 NAME

Lingua::PT::PLNbase - Perl extension for NLP of the Portuguese

=head1 SYNOPSIS

  use Lingua::PT::PLNbase;

  my @atomos = atomiza($texto);   # tb chamada 'tokenize'

  my $atomos_um_por_linha = tokeniza($texto);
  my $atomos_separados_por_virgula = tokeniza({fs => ','}, $texto);


  my @frases = frases($texto);

=head1 DESCRIPTION

Este módulo inclui funções básicas úteis ao processamento
computacional da língua, e em particular, da língua portuguesa.

=cut



our @EXPORT = qw(
   atomiza frases separa_frases fsentences atomos
   tokeniza has_accents remove_accents
   xmlsentences sentences
   cqptokens tokenize
);

our $VERSION = '0.28';

our $abrev;

our $terminador = qr{([.?!;]+[\»"'”’\«]?|<[pP]\b.*?>|<br>|\n\h*\n+|:\s+(?=[-\«"“‘„][A-Z]))};

our $itemmarkers1 =qr{
  (?:^|\n)\h*(
      \d\d?[)]\h                        # 4) 
    | [a-z][.)]\h                       # a)  b.
    | \([a-z1-9]\)\h                    # (a)
    | [.*►•●]                           # •
    | \d{1,3}[.]\h                      # 1.
    | \d{1,2}\.\d{1,2}[.)]\h            # 2.3.
    | \d{1,2}\.\d{1,2}\.\d{1,2}[.)]\h   # 2.3.3.
    )
}x;

our $itemmarkers2 =qr{         # not used yet
  \n\h*(
    | \<(li|LI)\>              # <li>
    | [‐‑–—\-]+                # --
    )
}x;

our $protect = qr!
       \#n\d+
    |  \w+['’]\w+
    |  \bn\.os?(?\![.\w])                        # number
    |  [\w_.-]+ \@ [\w_.-]+\w                    # emails
    |  \w+\.?[ºª°]\.?                            # ordinals
    |  _sec[:+].*?_                              # section marks from bookclean
    |  <[A-Za-z_](?:\w|:)*                       # <tag
         (?:\s+
            [A-Za-z_:0-9]+=                      #   at='v'
               (?: '[^']+'
               |   "[^"]+")
         )*
         \s*/?\s*
       >                                         # markup open XML SGML
    |  </\s*[A-Za-z_0-9:]+\s*>                   # markup close XML SGML
    |  \d+(?:\/\d+)+                             # dates or similar 12/21/1
    |  \d+(?:[.,]\d+)+%?                         # numbers
    |  \d+(?:\.[oa])+                            # ordinals numbers  12.
    |  (?:\d+\.)+(?=[ ]*[a-z0-9])                # numbers  12. (continuation)
    |  \d+\:\d+(\:\d+)?                          # the time         12:12:2
    |  (?:\&\w+\;)                               # entidades XML HTML
    |  (?:(?:https?|ftp|gopher|oai):|www)[\w_./~:-]+\w  # urls
     |  (?: \w+ \. )+ (?: com | org | net | pt )  # simplified urls
    |  \w+(-\w+)+                                # dá-lo-à  
    |  \\\\unicode\{\d+\}                        # unicode...
     |  \w+\.(?:exe|html?|zip|jpg|gif|wav|mp3|png|t?gz|pl|xml) # filenames
!xu;


our ($savit_n, %savit_p);
our %conf;


sub import {
  my $class = shift;
  our %conf = @_;
  $class->export_to_level(1, undef, @EXPORT);

  if ($conf{abbrev} && -f $conf{abbrev}) {
    $conf{ABBREV} = Lingua::PT::Abbrev->new($conf{abbrev});
  } else {
    $conf{ABBREV} = Lingua::PT::Abbrev->new();
  }

  $abrev = $conf{ABBREV}->regexp(nodot=>1);
}


sub _savit{
  my $a=shift;
  $savit_p{++$savit_n}=$a ;
  " __MARCA__$savit_n "
}

sub _loadit{
  my $a = shift;
  $a =~ s/ ?__MARCA__(\d+) ?/$savit_p{$1}/g;
  $savit_n = 0;
  $a;
}



sub _tokenizecommon {
  use utf8::all;
  my $conf = { keep_quotes => 0 };
  if (ref($_[0]) eq "HASH") {
    my $c = shift;
    $conf = {%$conf, %$c};
  }

  my $text = shift;

  for ($text) {
    s/<\?xml.*?\?>//s;

    if ($conf->{keep_quotes}) {
      s#\"# \" #g;
    } else {
      s/^\"/\« /g;
      s/ \"/ \« /g;
      s/\"([ .?!:;,])/ \» $1/g;
      s/\"$/ \»/g;
    }

    s!(\w)(['’](s|ld|nt|ll|m|t|re))\b!"$1 " . _savit($2)!ge;  # I 'm we 're can 't
    s!([[:alpha:]]+')(\w)!         _savit($1) . " $2"!ge;

    if ($conf->{keep_quotes}) {
      s#\'# \' #g;
    } else {
      s/^\`/\« /g;
      s/ \`/ \« /g;

      s/^\'/\« /g;
      s/ \'/ \« /g;
      s/\'([ .?!:;,])/ \» $1/g;
      s/\'$/ \»/g;
    }

    s!($protect)!      _savit($1)!xge;
    s!\b((([A-Z])\.)+)!_savit($1)!gie;

    s!([\»\]])!$1 !g; # » | ]
    s!([\«\[])! $1!g;

    s/(\s*\b\s*|\s+)/\n/g;

    # s/(.)\n-\n/$1-/g;
    s/\n+/\n/g;
    s/\n(\.?[ºª°])\b/$1/g;


    s#\n($abrev)\n\.\n#\n$1\.\n#ig;

    s#([\]\)])([.,;:!?])#$1\n$2#g;

    s/\n*</\n</;
    $_ = _loadit($_);
    s/(\s*\n)+$/\n/;
    s/^(\s*\n)+//;
  }
  $text
}

=head2 Atomizadores

Este módulo inclui um método configurável para a atomização de corpus
na língua portuguesa. No entanto, é possível que possa ser usado para
outras línguas (especialmente inglês e francês.

A forma simples de uso do atomizador é usando directamente a função
C<atomiza> que retorna um texto em que cada linha contém um átomo (ou
o uso da função C<tokeniza> que contém outra versão de atomizador).

As funções disponíveis:

=over 4

=item atomos

=item atomiza

=item tokenize

Usa um algorítmo desenvolvido no Projecto Natura.

Para que as aspas não sejam convertidas em I<abrir aspa> e I<fechar
aspa>, usar a opção de configuração C<keep_quotes>.

Retorna texto tokenizado, um por linha (a nao ser que o 'record
separator' (rs) seja redefenido). Em ambiente lista, retorna a lista
dos átomos.

  my @atomos = atomiza($texto);   # tb chamada 'tokenize'

  my $atomos_um_por_linha = tokeniza($texto);
  my $atomos_separados_por_virgula = tokeniza({fs => ','}, $texto);


=item tokeniza

Usa um algoritmo desenvolvido no Pólo de Oslo da Linguateca. Retorna
um átomo por linha em contexto escalar, e uma lista de átomos em
contexto de lista.

=item cqptokens

Um átomo por linha de acordo com notação CWB. Pode ser alterado o
separador de frases (ou de registo) usando a opção 'irs':

   cqptokens( { irs => "\n\n" }, "file" );

outras opções:

   cqptokens( { enc => ":utf8"}, "file" ); # enc => charset
                                           # outenc => charset

=back

=cut

sub atomos  { tokenize(@_) }
sub atomiza { tokenize(@_) }

sub tokenize{
  my $conf = { rs => "\n" };
  my $result = "";
  my $text = shift;

  if (ref($text) eq "HASH") {
    $conf = { %$conf, %$text };
    $text = shift;
  }

  die __PACKAGE__ . "::tokenize called with undefined value" unless defined $text;

  $result = _tokenizecommon($conf, $text);
  $result =~ s/\n$//g;

  if (wantarray) {
    return split /\n+/, $result
  } else {
    $result =~ s/\n/$conf->{rs}/g unless $conf->{rs} eq "\n";
    return $result;
  }
}

sub cqptokens{        ## 
  my %opt = ( irs => ">"); # irs => INPUT RECORD SEPARATOR; 
                           # enc => charset
                           # outenc => charset
  if(ref($_[0]) eq "HASH"){ %opt = (%opt , %{shift(@_)});}
  my $file = shift || "-";

  local $/ = $opt{irs};
  my %tag=();
  my ($a,$b);
  open(F,"$file");
  binmode(F,$opt{enc})         if $opt{enc};
  binmode(STDOUT,$opt{outenc}) if $opt{outenc};
  local $_;
  while(<F>) {
    if(/<(\w+)(.*?)>/){
      ($a, $b) = ($1,$2);
      if ($b =~ /=/ )  { $tag{'v'}{$a}++ }
      else             { $tag{'s'}{$a}++ }
    }
    print _tokenizecommon({},$_)
  }
  return \%tag
}



=head2 Segmentadores

Este módulo é uma extensão Perl para a segmentação de textos em
linguagem natural. O objectivo principal será a possibilidade de
segmentação a vários níveis, no entanto esta primeira versão permite
apenas a separação em frases (fraseação) usando uma de duas variantes:

=over 4

=item C<frases>

=item C<sentences>

  @frases = frases($texto);

Esta é a implementação do Projecto Natura, que retorna uma lista de
frases.

=item C<separa_frases>

  $frases = separa_frases($texto);

Esta é a implementação da Linguateca, que retorna um texto com uma
frase por linha.

=item C<xmlsentences>

Utiliza o método C<frases> e aplica uma etiqueta XML a cada frase. Por omissão,
as frases são ladeadas por '<s>' e '</s>'. O nome da etiqueta pode ser
substituído usando o parametro opcional C<st>.

  xmlsentences({st=> "tag"}, text)

=back

=cut

sub xmlsentences {
  my %opt = (st => "s") ;
  if (ref($_[0]) eq "HASH"){ %opt = (%opt , %{shift(@_)});}
  my $par=shift;
  join("\n",map {"<$opt{st}>$_</$opt{st}>"} (sentences($par)));
}



sub frases { sentences(@_) }
sub sentences{
  use utf8::all;
  my @r;
  my $MARCA = "\0x01";
  my $par = shift;
  for ($par) {
    s!($itemmarkers1)!_savit("$MARCA$1$MARCA")!ge;
    s!($protect)!          _savit($1)!xge;
    s!\b(($abrev)\.)!      _savit($1)!ige;
    s!\b(([A-Z])\.)!       _savit($1)!gie;  # este à parte para não apanhar minúlculas (s///i)
    s!($terminador)!$1$MARCA!g;
    $_ = _loadit($_);
    @r = split(/\s*(?:$MARCA\s*)/,$_);
  }
  #if (@r && $r[-1] =~ /^\s*$/s) {
  #  pop(@r)
  #}
  return map { _trim($_) } @r;
}

sub _trim {
  my $x = shift;
  $x =~ s/^[\n\r\s]+//;
  $x =~ s/[\n\r\s]+$//;
  if($x =~ /\S/){return ($x)}
  else          {return (  )}
}


=head2 Segmentação a vários níveis

=over 4

=item fsentences

A função C<fsentences> permite segmentar um conjunto de ficheiros a
vários níveis: por ficheiro, por parágrafo ou por frase. O output pode
ser realizado em vários formatos e obtendo, ou não, numeração de
segmentos.

Esta função é invocada com uma referência para um hash de configuração
e uma lista de ficheiros a processar (no caso de a lista ser vazia,
irá usar o C<STDIN>).

O resultado do processamento é enviado para o C<STDOUT> a não ser que
a chave C<output> do hash de configuração esteja definida. Nesse caso,
o seu valor será usado como ficheiro de resultado.

A chave C<input_p_sep> permite definir o separador de parágrafos. Por
omissão, é usada uma linha em branco.

A chave C<o_format> define as políticas de etiquetação do
resultado. De momento, a única política disponível é a C<XML>.

As chaves C<s_tag>, C<p_tag> e C<t_tag> definem as etiquetas a usar,
na política XML, para etiquetar frases, parágrafos e textos
(ficheiros), respectivamente. Por omissão, as etiquetas usadas são
C<s>, C<p> e C<text>.

É possível numerar as etiquetas, definindo as chaves C<s_num>,
C<p_num> ou C<t_num> da seguinte forma:

=over 4

=item '0'

Nenhuma numeração.

=item 'f'

Só pode ser usado com o C<t_tag>, e define que as etiquetas que
delimitam ficheiros usará o nome do ficheiro como identificador.

=item '1'

Numeração a um nível. Cada etiqueta terá um contador diferente.

=item '2'

Só pode ser usado com o C<p_tag> ou o C<s_tag> e obriga à numeração a
dois níveis (N.N).

=item '3'

Só pode ser usado com o C<s_tag> e obriga à numeração a três níveis (N.N.N)

=back

=back


 nomes das etiquetas (s => 's', p=>'p', t=>'text')

 t: 0 - nenhuma
    1 - numeracao
    f - ficheiro [DEFAULT]

 p: 0 - nenhuma
    1 - numeracao 1 nivel [DEFAULT]
    2 - numercao 2 niveis (N.N)

 s: 0 - nenhuma
    1 - numeração 1 nível [DEFAULT]
    2 - numeração 2 níveis (N.N)
    3 - numeração 3 níveis (N.N.N)

=cut

sub fsentences {
  use utf8::all; 
  my %opts = (
	      o_format => 'XML',
	      s_tag    => 's',
	      s_num    => '1',
	      s_last   => '',

	      p_tag    => 'p',
	      p_num    => '1',
	      p_last   => '',

	      t_tag    => 'text',
	      t_num    => 'f',
	      t_last   => '',

	      tokenize => 0,

	      output   => \*STDOUT,
	      input_p_sep => '',
	     );

  %opts = (%opts, %{shift()}) if ref($_[0]) eq "HASH";


  my @files = @_;
  @files = (\*STDIN) unless @files;

  my $oldselect;
  if (!ref($opts{output})) {
    open OUT, ">$opts{output}" or die("Cannot open file for writting: $!\n");
    $oldselect = select OUT;
  }

  for my $file (@files) {
    my $fh;
    if (ref($file)) {
      $fh = $file;
    } else {
	if ($opts{enc}) {
	    open $fh, "<$opts{enc}", $file or die("Cannot open file $file:$!\n");
	} else {
	    open $fh, $file or die("Cannot open file $file:$!\n");
	}
      print _open_t_tag(\%opts, $file);
    }

    my $par;
    local $/ = $opts{input_p_sep};
    while ($par = <$fh>) {
      print _open_p_tag(\%opts);

      chomp($par);

      for my $s (sentences($par)) {
	print _open_s_tag(\%opts), _clean(\%opts,$s), _close_s_tag(\%opts);
      }

      print _close_p_tag(\%opts);
    }


    unless (ref($file)) {
      print _close_t_tag(\%opts);
      close $fh
    }

  }

  if (!ref($opts{output})) {
    close OUT;
    select $oldselect;
  }

}

sub _clean {
  my $opts = shift;
  my $str = shift;

  if ($opts->{tokenize}) {
      if ($opts->{tokenize} eq "cqp") {
          $str = "\n".join("\n", atomiza($str))."\n"
      } else {
          $str = join(" ", atomiza($str))
      }
  } else {
    $str =~ s/\s+/ /g;
  }
  $str =~ s/&/&amp;/g;
  $str =~ s/>/&gt;/g;
  $str =~ s/</&lt;/g;
  return $str;
}

sub _open_t_tag {
  my $opts = shift;
  my $file = shift || "";
  if ($opts->{o_format} eq "XML" &&
      $opts->{t_tag}) {
    if ($opts->{t_num} eq 0) {
      return "<$opts->{t_tag}>\n";
    } elsif ($opts->{t_num} eq 'f') {
      $opts->{t_last} = $file;
      $opts->{p_last} = 0;
      $opts->{s_last} = 0;
      return "<$opts->{t_tag} file=\"$file\">\n";
    } else {
      ## t_num = 1 :-)
      ++$opts->{t_last};
      $opts->{p_last} = 0;
      $opts->{s_last} = 0;
      return "<$opts->{t_tag} id=\"$opts->{t_last}\">\n";
    }
  }
  return "" if ($opts->{o_format} eq "NATools");
}

sub _close_t_tag {
  my $opts = shift;
  my $file = shift || "";
  if ($opts->{o_format} eq "XML" &&
      $opts->{t_tag}) {
    return "</$opts->{t_tag}>\n";
  }
  return "" if ($opts->{o_format} eq "NATools");
}

sub _open_p_tag {
  my $opts = shift;

  if ($opts->{o_format} eq "XML" &&
      $opts->{p_tag}) {
    if ($opts->{p_num} == 0) {
      return "<$opts->{p_tag}>\n";
    } elsif ($opts->{p_num} == 1) {
      ++$opts->{p_last};
      $opts->{s_last} = 0;
      return "<$opts->{p_tag} id=\"$opts->{p_last}\">\n";
    } else {
      ## p_num = 2
      ++$opts->{p_last};
      $opts->{s_last} = 0;
      return "<$opts->{p_tag} id=\"$opts->{t_last}.$opts->{p_last}\">\n";
    }
  }
  return "" if ($opts->{o_format} eq "NATools");
}

sub _close_p_tag {
  my $opts = shift;
  my $file = shift || "";
  if ($opts->{o_format} eq "XML" &&
      $opts->{p_tag}) {
    return "</$opts->{p_tag}>\n";
  }
  return "" if ($opts->{o_format} eq "NATools");
}


sub _open_s_tag {
  my $opts = shift;

  if ($opts->{o_format} eq "XML" &&
      $opts->{s_tag}) {
    if ($opts->{s_num} == 0) {
      return "<$opts->{s_tag}>";
    } elsif ($opts->{s_num} == 1) {
      ++$opts->{s_last};
      return "<$opts->{s_tag} id=\"$opts->{s_last}\">";

    } elsif ($opts->{s_num} == 2) {
      ++$opts->{s_last};
      return "<$opts->{s_tag} id=\"$opts->{p_last}.$opts->{s_last}\">";

    } else {
      ## p_num = 3
      ++$opts->{s_last};
      return "<$opts->{s_tag} id=\"$opts->{t_last}.$opts->{p_last}.$opts->{s_last}\">";
    }
  }
  return "" if ($opts->{o_format} eq "NATools");
}

sub _close_s_tag {
  my $opts = shift;
  my $file = shift || "";
  if ($opts->{o_format} eq "XML" &&
      $opts->{s_tag}) {
    return "</$opts->{s_tag}>\n";
  }
  return "\n\$\n" if ($opts->{o_format} eq "NATools");
}





=head2 Acentuação

=over 4

=item remove_accents

Esta função remove a acentuação do texto passado como parâmetro

=item has_accents

Esta função verifica se o texto passado como parâmetro tem caracteres acentuados

=back

=cut

sub has_accents {
  my $word = shift;
  if ($word =~ m![çáéíóúàèìòùãõâêîôûäëïöüñ]!i) {
    return 1
  } else {
    return 0
  }
}

sub remove_accents {
  my $word = shift;
  $word =~ tr/çáéíóúàèìòùãõâêîôûäëïöüñ/caeiouaeiouaoaeiouaeioun/;
  $word =~ tr/ÇÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÑ/CAEIOUAEIOUAOAEIOUAEIOUN/;
  return $word;
}





### ---------- OSLO --------

sub tokeniza {
  use utf8::all;
  my $par = shift;

  for ($par) {
    s/([!?]+)/ $1/g;
    s/([.,;\»´])/ $1/g;

    # separa os dois pontos só se não entre números 9:30...
    s/:([^0-9])/ :$1/g;

    # separa os dois pontos só se não entre números e não for http:/...
    s/([^0-9]):([^\/])/$1 :$2/g;

    # was s/([«`])/$1 /g; -- mas tava a dar problemas com o emacs :|
    s!([`])!$1 !g;

    # só separa o parêntesis esquerdo quando não engloba números ou asterisco
    s/\(([^1-9*])/\( $1/g;

    # só separa o parêntesis direito quando não engloba números ou asterisco ou percentagem
    s/([^0-9*%])\)/$1 \)/g;

    # desfaz a separação dos parênteses para B)
    s/> *([A-Za-z]) \)/> $1\)/g;

    # desfaz a separação dos parênteses para (a)
    s/> *\( ([a-z]) \)/> \($1\)/g;

    # separação dos parênteses para ( A4 )
    s/(\( +[A-Z]+[0-9]+)\)/ $1 \)/g;

    # separa o parêntesis recto esquerdo desde que não [..
    s/\[([^.§])/[ $1/g;

    # separa o parêntesis recto direito desde que não ..]
    s/([^.§])\]/$1 ]/g;

    # separa as reticências só se não dentro de [...]
    s/([^[])§/$1 §/g;

    # desfaz a separação dos http:
    s/http :/http:/g;

    # separa as aspas anteriores
    s/ \"/ \« /g;

    # separa as aspas anteriores mesmo no inicio
    s/^\"/ \« /g;

    # separa as aspas posteriores
    s/\" / \» /g;

    # separa as aspas posteriores mesmo no fim
    s/\"$/ \»/g;

    # trata dos apóstrofes
    # trata do apóstrofe: só separa se for pelica
    s/([^dDlL])\'([\s\',:.?!])/$1 \'$2/g;
    # trata do apóstrofe: só separa se for pelica
    s/(\S[dDlL])\'([\s\',:.?!])/$1 \'$2/g;
    # separa d' do resto da palavra "d'amor"... "dest'época"
    s/([A-ZÊÁÉÍÓÚÀÇÔÕÃÂa-zôõçáéíóúâêàã])\'([A-ZÊÁÉÍÓÚÀÇÔÕÃÂa-zôõçáéíóúâêàã])/$1\' $2/;

    #Para repor PME's
    s/(\s[A-Z]+)\' s([\s,:.?!])/$1\'s$2/g;

    # isto é para o caso dos apóstrofos não terem sido tratados pelo COMPARA
    # separa um apóstrofe final usado como inicial
    s/ '([A-Za-zÁÓÚÉÊÀÂÍ])/ ' $1/g;
    # separa um apóstrofe final usado como inicial
    s/^'([A-Za-zÁÓÚÉÊÀÂÍ])/' $1/g;

    # isto é para o caso dos apóstrofes (plicas) serem os do COMPARA
    s/\`([^ ])/\` $1/g;
    s/([^ ])´/$1 ´/g;

    # trata dos (1) ou 1)
    # separa casos como Rocha(1) para Rocha (1)
    s/([a-záéãó])\(([0-9])/$1 \($2/g;
    # separa casos como dupla finalidade:1)
    s/:([0-9]\))/ : $1/g;

    # trata dos hífenes
    # separa casos como (Itália)-Juventus para Itália) -
    s/\)\-([A-Z])/\) - $1/g;
    # separa casos como 1-universidade
    s/([0-9]\-)([^0-9\s])/$1 $2/g;
  }

  #trata das barras
  #se houver palavras que nao sao todas em maiusculas, separa
  my @barras = ($par=~m%(?:[a-z]+/)+(?:[A-Za-z][a-z]*)%g);
  my $exp_antiga;
  foreach my $exp_com_barras (@barras) {
    if (($exp_com_barras !~ /[a-z]+a\/o$/) and # Ambicioso/a
        ($exp_com_barras !~ /[a-z]+o\/a$/) and # cozinheira/o
        ($exp_com_barras !~ /[a-z]+r\/a$/)) { # desenhador/a
             $exp_antiga=$exp_com_barras;
             $exp_com_barras=~s#/# / #g;
             $par=~s/$exp_antiga/$exp_com_barras/g;
	   }
  }

  for ($par) {
    s# e / ou # e/ou #g;
    s#([Kk])m / h#$1m/h#g;
    s# mg / kg# mg/kg#g;
    s#r / c#r/c#g;
    s#m / f#m/f#g;
    s#f / m#f/m#g;
  }


  if (wantarray) {
    return split /\s+/, $par
  } else {
    $par =~ s/\s+/\n/g;
    return $par
  }
}



sub tratar_pontuacao_interna {
  use utf8::all;
  my $par = shift;

  #    print "Estou no pontuação interna... $par\n";

  for ($par) {
    # proteger o §
    s/§/§§/g;

    # tratar das reticências
    s/\.\.\.+/§/g;

    s/\+/\+\+/g;

    # tratar de iniciais seguidas por ponto, eventualmente com
    # parênteses, no fim de uma frase
    s/([A-Z])\. ([A-Z])\.(\s*[])]*\s*)$/$1+ $2+$3 /g;

    # iniciais com espaço no meio...
    s/ a\. C\./ a+C+/g;
    s/ d\. C\./ d+C+/g;

    # tratar dos pontos nas abreviaturas
    s/\.º/º+/g;
    s/º\./+º/g;
    s/\.ª/+ª/g;
    s/ª\./ª+/g;

    #só mudar se não for ambíguo com ponto final
    s/º\. +([^A-ZÀÁÉÍÓÚÂÊ\«])/º+ $1/g;

    # formas de tratamento
    s/Ex\./Ex+/g; # Ex.
    s/ ex\./ ex+/g; # ex.
    s/Exa(s*)\./Exa$1+/g; # Exa., Exas.
    s/ exa(s*)\./ exa$1+/g; # exa., exas
    s/Pe\./Pe+/g;
    s/Dr(a*)\./Dr$1+/g; # Dr., Dra.
    s/ dr(a*)\./ dr$1+/g; # dr., dra.
    s/ drs\./ drs+/g; # drs.
    s/Eng(a*)\./Eng$1+/g; # Eng., Enga.
    s/ eng(a*)\./ eng$1+/g; # eng., enga.
    s/([Ss])r(t*)a\./$1r$2a+/g; # Sra., sra., Srta., srta.
    s/([Ss])r(s*)\./$1r$2+/g; # Sr., sr., Srs., srs.
    s/ arq\./ arq+/g; # arq.
    s/Prof(s*)\./Prof$1+/g; # Prof., Profs.
    s/Profa(s*)\./Profa$1+/g; # Profa., Profas.
    s/ prof(s*)\./ prof$1+/g; # prof., profs.
    s/ profa(s*)\./ profa$1+/g; # profa., profas.
    s/\. Sen\./+ Sen+/g; # senador (vem sempre depois de Av. ou R. ...)
    s/ua Sen\./ua Sen+/g; # senador (depois [Rr]ua ...)
    s/Cel\./Cel+/g; # coronel
    s/ d\. / d+ /g; # d. Luciano

    # partes de nomes (pospostos)
    s/ ([lL])da\./ $1da+/g; # limitada
    s/ cia\./ cia+/g; # companhia
    s/Cia\./Cia+/g; # companhia
    s/Jr\./Jr+/g;

    # moradas
    s/Av\./Av+/g;
    s/ av\./ av+/g;
    s/Est(r*)\./Est$1+/g;
    s/Lg(o*)\./Lg$1+/g;
    s/ lg(o*)\./ lg$1+/g;
    s/T(ra)*v\./T$1v+/g; # Trav., Tv.
    s/([^N])Pq\./$1Pq+/g; # Parque (cuidado com CNPq)
    s/ pq\./ pq+/g; # parque
    s/Jd\./Jd+/g; # jardim
    s/Ft\./Ft+/g; # forte
    s/Cj\./Cj+/g; # conjunto
    s/ ([lc])j\./ $1j+/g; # conjunto ou loja
    #    $par=~s/ al\./ al+/g; # alameda tem que ir para depois de et.al...

    # Remover aqui uns warningzitos
    s/Tel\./Tel+/g; # Tel.
    s/Tel(e[fm])\./Tel$1+/g; #  Telef., Telem.
    s/ tel\./ tel+/g; # tel.
    s/ tel(e[fm])\./ tel$1+/g; #  telef., telem.
    s/Fax\./Fax+/g; # Fax.
    s/ cx\./ cx+/g; # caixa

    # abreviaturas greco-latinas
    s/ a\.C\./ a+C+/g;
    s/ a\.c\./ a+c+/g;
    s/ d\.C\./ d+C+/g;
    s/ d\.c\./ d+c+/g;
    s/ ca\./ ca+/g;
    s/etc\.([.,;])/etc+$1/g;
    s/etc\.\)([.,;])/etc+)$1/g;
    s/etc\. --( *[a-záéíóúâêà,])/etc+ --$1/g;
    s/etc\.(\)*) ([^A-ZÀÁÉÍÓÂÊ])/etc+$1 $2/g;
    s/ et\. *al\./ et+al+/g;
    s/ al\./ al+/g; # alameda
    s/ q\.b\./ q+b+/g;
    s/ i\.e\./ i+e+/g;
    s/ibid\./ibid+/g;
    s/ id\./ id+/g; # se calhar é preciso ver se não vem sempre precedido de um (
    s/op\.( )*cit\./op+$1cit+/g;
    s/P\.S\./P+S+/g;

    # unidades de medida
    s/([0-9][hm])\. ([^A-ZÀÁÉÍÓÚÂÊ])/$1+ $2/g; # 19h., 24m.
    s/([0-9][km]m)\. ([^A-ZÀÁÉÍÓÚÂÊ])/$1+ $2/g; # 20km., 24mm.
    s/([0-9]kms)\. ([^A-ZÀÁÉÍÓÚÂÊ])/$1+ $2/g; # kms. !!
    s/(\bm)\./$1+/g; # metros no MINHO

    # outros
    s/\(([Oo]rgs*)\.\)/($1+)/g; # (orgs.)
    s/\(([Ee]ds*)\.\)/($1+)/g; # (eds.)
    s/séc\./séc+/g;
    s/pág(s*)\./pág$1+/g;
    s/pg\./pg+/g;
    s/pag\./pag+/g;
    s/ ed\./ ed+/g;
    s/Ed\./Ed+/g;
    s/ sáb\./ sáb+/g;
    s/ dom\./ dom+/g;
    s/ id\./ id+/g;
    s/ min\./ min+/g;
    s/ n\.o(s*) / n+o$1 /g; # abreviatura de numero no MLCC-DEB
    s/ ([Nn])o\.(s*)\s*([0-9])/ $1o+$2 $3/g; # abreviatura de numero no., No.
    s/ n\.(s*)\s*([0-9])/ n+$1 $2/g; # abreviatura de numero n. no ANCIB
    s/ num\. *([0-9])/ num+ $1/g; # abreviatura de numero num. no ANCIB
    s/ c\. ([0-9])/ c+ $1/g; # c. 1830
    s/ p\.ex\./ p+ex+/g;
    s/ p\./ p+/g;
    s/ pp\./ pp+/g;
    s/ art(s*)\./ art$1+/g;
    s/Min\./Min+/g;
    s/Inst\./Inst+/g;
    s/vol(s*)\./vol$1+ /g;
    s/ v\. *([0-9])/ v+ $1/g; # abreviatura de volume no ANCIB
    s/\(v\. *([0-9])/\(v+ $1/g; # abreviatura de volume no ANCIB
    s/^v\. *([0-9])/v+ $1/g; # abreviatura de volume no ANCIB
    s/Obs\./Obs+/g;

    # Abreviaturas de meses
    s/(\W)jan\./$1jan+/g;
    s/\Wfev\./$1fev+/g;
    s/(\/\s*)mar\.(\s*[0-9\/])/$1mar+$2/g; # a palavra "mar"
    s/(\W)mar\.(\s*[0-9]+)/$1mar\+$2/g;
    s/(\W)abr\./$1abr+/g;
    s/(\W)mai\./$1mai+/g;
    s/(\W)jun\./$1jun+/g;
    s/(\W)jul\./$1jul+/g;
    s/(\/\s*)ago\.(\s*[0-9\/])/$1ago+$2/g; # a palavra inglesa "ago"
    s/ ago\.(\s*[0-9\/])/ ago+$1/g; # a palavra inglesa "ago./"
    s/(\W)set\.(\s*[0-9\/])/$1set+$2/g; # a palavra inglesa "set"
    s/([ \/])out\.(\s*[0-9\/])/$1out+$2/g; # a palavra inglesa "out"
    s/(\W)nov\./$1nov+/g;
    s/(\/\s*)dez\.(\s*[0-9\/])/$1dez+$2/g; # a palavra "dez"
    s/(\/\s*)dez\./$1dez+/g; # a palavra "/dez."

    # Abreviaturas inglesas
    s/Bros\./Bros+/g;
    s/Co\. /Co+ /g;
    s/Co\.$/Co+/g;
    s/Com\. /Com+ /g;
    s/Com\.$/Com+/g;
    s/Corp\. /Corp+ /g;
    s/Inc\. /Inc+ /g;
    s/Ltd\. /Ltd+ /g;
    s/([Mm])r(s*)\. /$1r$2+ /g;
    s/Ph\.D\./Ph+D+/g;
    s/St\. /St+ /g;
    s/ st\. / st+ /g;

    # Abreviaturas francesas
    s/Mme\./Mme+/g;

    # Abreviaturas especiais do Diário do Minho
    s/ habilit\./ habilit+/g;
    s/Hab\./Hab+/g;
    s/Mot\./Mot+/g;
    s/\-Ang\./-Ang+/g;
    s/(\bSp)\./$1+/g; # Sporting
    s/(\bUn)\./$1+/g; # Universidade

    # Abreviaturas especiais do Folha
    s/([^'])Or\./$1Or+/g; # alemanha Oriental, evitar d'Or
    s/Oc\./Oc+/g; # alemanha Ocidental

  }

  # tratar dos conjuntos de iniciais
  my @siglas_iniciais = ($par =~ /^(?:[A-Z]\. *)+[A-Z]\./);
  my @siglas_finais   = ($par =~ /(?:[A-Z]\. *)+[A-Z]\.$/);
  my @siglas = ($par =~ m#(?:[A-Z]\. *)+(?:[A-Z]\.)(?=[]\)\s,;:!?/])#g); #trata de conjuntos de iniciais
  push (@siglas, @siglas_iniciais);
  push (@siglas, @siglas_finais);
  my $sigla_antiga;
  foreach my $sigla (@siglas) {
    $sigla_antiga = $sigla;
    $sigla =~ s/\./+/g;
    $sigla_antiga =~ s/\./\\\./g;
    #	print "SIGLA antes: $sigla, $sigla_antiga\n";
    $par =~ s/$sigla_antiga/$sigla/g;
    #	print "SIGLA: $sigla\n";
  }

  # tratar de pares de iniciais ligadas por hífen (à francesa: A.-F.)
  for ($par) {
    s/ ([A-Z])\.\-([A-Z])\. / $1+-$2+ /g;
    # tratar de iniciais (únicas?) seguidas por ponto
    s/ ([A-Z])\. / $1+ /g;
    # tratar de iniciais seguidas por ponto
    s/^([A-Z])\. /$1+ /g;
    # tratar de iniciais seguidas por ponto antes de aspas "D. João
    # VI: Um Rei Aclamado"
    s/([("\«])([A-Z])\. /$1$2+ /g;
  }

  # Tratar dos URLs (e também dos endereços de email)
  # email= url@url...
  # aceito endereços seguidos de /hgdha/hdga.html
  #  seguidos de /~hgdha/hdga.html
  #    @urls=($par=~/(?:[a-z][a-z0-9-]*\.)+(?:[a-z]+)(?:\/~*[a-z0-9-]+)*?(?:\/~*[a-z0-9][a-z0-9.-]+)*(?:\/[a-z.]+\?[a-z]+=[a-z0-9-]+(?:\&[a-z]+=[a-z0-9-]+)*)*/gi);

  my @urls = ($par =~ /(?:[a-z][a-z0-9-]*\.)+(?:[a-z]+)(?:\/~*[a-z0-9][a-z0-9.-]+)*(?:\?[a-z]+=[a-z0-9-]+(?:\&[a-z]+=[a-z0-9-]+)*)*/gi);
  my $url_antigo;
  foreach my $url (@urls) {
    $url_antigo = $url;
    $url_antigo =~ s/\./\\./g; # para impedir a substituição de P.o em vez de P\.o
    $url_antigo =~ s/\?/\\?/g;
    $url =~ s/\./+/g;
    # Se o último ponto está mesmo no fim, não faz parte do URL
    $url =~ s/\+$/./;
    $url =~ s/\//\/\/\/\//g; # põe quatro ////
    $par =~ s/$url_antigo/$url/;
  }
  # print "Depois de tratar dos URLs: $par\n";

  for ($par) {
    # de qualquer maneira, se for um ponto seguido de uma vírgula, é
    # abreviatura...
    s/\. *,/+,/g;
    # de qualquer maneira, se for um ponto seguido de outro ponto, é
    # abreviatura...
    s/\. *\./+./g;

    # tratamento de numerais
    s/([0-9]+)\.([0-9]+)\.([0-9]+)/$1_$2_$3/g;
    s/([0-9]+)\.([0-9]+)/$1_$2/g;

    # tratamento de numerais cardinais
    # - tratar dos números com ponto no início da frase
    s/^([0-9]+)\. /$1+ /g;
    # - tratar dos números com ponto antes de minúsculas
    s/([0-9]+)\. ([a-záéíóúâêà])/$1+ $2/g;

    # tratamento de numerais ordinais acabados em .o
    s/([0-9]+)\.([oa]s*) /$1+$2 /g;
    # ou expressos como 9a.
    s/([0-9]+)([oa]s*)\. /$1$2+ /g;

    # tratar numeracao decimal em portugues
    s/([0-9]),([0-9])/$1#$2/g;

    #print "TRATA: $par\n";

    # tratar indicação de horas
    #   esta é tratada na tokenização - não separando 9:20 em 9 :20
  }
  return $par;
}


sub separa_frases {
  use utf8::all;
  my $par = shift;

  # $num++;

  $par = &tratar_pontuacao_interna($par);

  #  print "Depois de tratar_pontuacao_interna: $par\n";

  for ($par) {

    # primeiro junto os ) e os -- ao caracter anterior de pontuação
    s/([?!.])\s+\)/$1\)/g; # pôr  "ola? )" para "ola?)"
    s/([?!.])\s+\-/$1-/g; # pôr  "ola? --" para "ola?--"
    s/([?!.])\s+§/$1§/g; # pôr  "ola? ..." para "ola?..."
    s/§\s+\-/$1-/g; # pôr  "ola§ --" para "ola§--"

    # junto tb o travessão -- `a pelica '
    s/\-\- \' *$/\-\-\' /;

    # separar esta pontuação, apenas se não for dentro de aspas, ou
    # seguida por vírgulas ou parênteses o a-z estáo lá para não
    # separar /asp?id=por ...
    s/([?!]+)([^-\»'´,§?!)"a-z])/$1.$2/g;

    # Deixa-se o travessão para depois
    # print "Depois de tratar do ?!: $par";

    # separar as reticências entre parênteses apenas se forem seguidas
    # de nova frase, e se não começarem uma frase elas próprias
    s/([\w?!])§([\»"´']*\)) *([A-ZÁÉÍÓÚÀ])/$1§$2.$3/g;

    # print "Depois de tratar das retic. seguidas de ): $par";

    # separar os pontos antes de parênteses se forem seguidos de nova
    # frase
    s/([\w])\.([)]) *([A-ZÁÉÍÓÚÀ])/$1 + $2.$3/g;

    # separar os pontos ? e ! antes de parênteses se forem seguidos de
    # nova frase, possivelmente tb iniciada por abre parênteses ou
    # travessão
    s/(\w[?!]+)([)]) *((?:\( |\-\- )*[A-ZÁÉÍÓÚÀ])/$1 $2.$3/g;

    # separar as reticências apenas se forem seguidas de nova frase, e
    # se não começarem uma frase elas próprias trata também das
    # reticências antes de aspas
    s/([\w\d!?])\s*§(["\»'´]*) ([^\»"'a-záéíóúâêàäëïöü,;?!)])/$1§$2.$3/g;
    s/([\w\d!?])\s*§(["\»'´]*)\s*$/$1§$2. /g;

    # aqui trata das frases acabadas por aspas, eventualmente tb
    # fechando parênteses e seguidas por reticências
    s/([\w!?]["\»'´])§(\)*) ([^\»"a-záéíóúâêàäëïöü,;?!)])/$1§$2.$3/g;

    #print "depois de tratar das reticencias seguidas de nova frase: $par\n";

    # tratar dos dois pontos: apenas se seguido por discurso directo
    # em maiúsculas
    s/: \«([A-ZÁÉÍÓÚÀ])/:.\«$1/g;
    s/: (\-\-[ \«]*[A-ZÁÉÍÓÚÀ])/:.$1/g;

    # tratar dos dois pontos se eles acabam o parágrafo (é preciso pôr
    # um espaço)
    s/:\s*$/:. /;

    # tratar dos pontos antes de aspas
    s/\.(["\»'´])([^.])/+$1.$2/g;

    # tratar das aspas quando seguidas de novas aspas
    s/\»\s*[\«"]/\». \«/g;

    # tratar de ? e ! seguidos de aspas quando seguidos de maiúscula
    # eventualmente iniciados por abre parênteses ou por travessão
    s/([?!])([\»"'´]) ((?:\( |\-\- )*[A-ZÁÉÍÓÚÀÊÂ])/$1$2. $3/g;

    # separar os pontos ? e ! antes de parênteses e possivelmente
    # aspas se forem o fim do parágrafo
    s/(\w[?!]+)([)][\»"'´]*) *$/$1 $2./;

    # tratar dos pontos antes de aspas precisamente no fim
    s/\.([\»"'´])\s*$/+$1. /g;

    # tratar das reticências e outra pontuação antes de aspas ou
    # plicas precisamente no fim
    s/([!?§])([\»"'´]+)\s*$/$1$2. /g;

    #tratar das reticências precisamente no fim
    s/§\s*$/§. /g;

    # tratar dos pontos antes de parêntesis precisamente no fim
    s/\.\)\s*$/+\). /g;

    # aqui troco .) por .). ...
    s/\.\)\s/+\). /g;
  }

  # tratar de parágrafos que acabam em letras, números, vírgula ou
  # "-", chamando-os fragmentos #ALTERACAO
  my $fragmento;
  if ($par =~/[A-Za-záéíóúêãÁÉÍÓÚÀ0-9\),-][\»\"\'´>]*\s*\)*\s*$/) {
    $fragmento = 1
  }

  for ($par) {
    # se o parágrafo acaba em "+", deve-se juntar "." outra vez.
    s/([^+])\+\s*$/$1+. /;

    # se o parágrafo acaba em abreviatura (+) seguido de aspas ou parêntesis, deve-se juntar "."
    s/([^+])\+\s*(["\»'´\)])\s*$/$1+$2. /;

    # print "Parágrafo antes da separação: $par";
  }

  my @sentences = split /\./,$par;
  if (($#sentences > 0) and not $fragmento) {
    pop(@sentences);
  }

  my $resultado = "";
  # para saber em que frase pôr <s frag>
  my $num_frase_no_paragrafo = 0;
  foreach my $frase (@sentences) {
    $frase = &recupera_ortografia_certa($frase);

    if (($frase=~/[.?!:;][\»"'´]*\s*$/) or
	($frase=~/[.?!] *\)[\»"'´]*$/)) {
      # frase normal acabada por pontuação
      $resultado .= "<s> $frase </s>\n";
    }

    elsif (($fragmento) and ($num_frase_no_paragrafo == $#sentences)) {
      $resultado .= "<s frag> $frase </s>\n";
      $fragmento = 0;
    }
    else {
      $resultado .= "<s> $frase . </s>\n";
    }
    $num_frase_no_paragrafo++;
  }

  return $resultado;
}


sub recupera_ortografia_certa {
  use utf8::all;
  # os sinais literais de + são codificados como "++" para evitar
  # transformação no ponto, que é o significado do "+"

  my $par = shift;

  for ($par) {
    s/([^+])\+(?!\+)/$1./g; # um + não seguido por +
    s/\+\+/+/g;
    s/^§(?!§)/.../g; # se as reticências começam a frase
    s/([^§(])§(?!§)\)/$1... \)/g; # porque se juntou no separa_frases 
    # So nao se faz se for (...) ...
    s/([^§])§(?!§)/$1.../g; # um § não seguido por §
    s/§§/§/g;
    s/_/./g;
    s/#/,/g;
    s#////#/#g; #passa 4 para 1
    s/([?!])\-/$1 \-/g; # porque se juntou no separa_frases
    s/([?!])\)/$1 \)/g; # porque se juntou no separa_frases 
  }
  return $par;
}


1;
__END__


=head2 Funções auxiliares

=over 4

=item recupera_ortografia_certa

=item tratar_pontuacao_interna

=back

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Alberto Simoes (ambs@di.uminho.pt)

Diana Santos (diana.santos@sintef.no)

José João Almeida (jj@di.uminho.pt)

Paulo Rocha (paulo.rocha@di.uminho.pt)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2006 by its authors

(EN)
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

(PT)
Esta biblioteca é software de domínio público; pode redistribuir e/ou
modificar este módulo nos mesmos termos do próprio Perl, quer seja a
versão 5.8.1 ou, na sua liberdade, qualquer outra versão do Perl 5 que
tenha disponível.

=cut


