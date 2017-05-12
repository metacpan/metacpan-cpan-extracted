package Lingua::PT::PLN;
use strict;


use Lingua::PT::PLNbase;
#use Lingua::PT::PLN::Words2Sampa;

require Exporter;
our @ISA = qw(Exporter AutoLoader);

our @EXPORT = 
  (@Lingua::PT::PLNbase::EXPORT,
   qw(syllable accent wordaccent oco initPhon toPhon));

our $VERSION = '0.22';

use POSIX qw(locale_h);
setlocale(&POSIX::LC_ALL, "pt_PT");
use locale;

# para transcriÁ„o fonÈtica
$INC{'Lingua/PT/PLN.pm'} =~ m!/PLN\.pm$!;
our $ptpho = "$`/PLN/ptpho";
our $naoacentuadas = "$`/PLN/nao_acentuadas";
our $dic;
our $no_accented;

our ($consoante, $vogal, $acento, %names);

my ($lmax,$maxlog,$magicF);

BEGIN {
  $consoante=qr{[bcÁdfghjklmÒnpqrstvwyxz]}i;
  $vogal=qr{[·ÈÌÛ˙‚ÍÙ„ı‡Ëaeiou¸ˆ‰ÎÔ]}i;
  $acento=qr{[·ÈÌÛ˙‚ÍÙ„ı¸ˆ‰ÎÔ]}i;
  setlocale(&POSIX::LC_ALL, "pt_PT");

  use POSIX;
  POSIX::setlocale(LC_CTYPE,"pt_PT");

  $lmax = 1000000;
  $maxlog = 13.815;
  $magicF = $maxlog/log($lmax);
}



sub oco {
  ### { from => (file|string),
  ###    num => 1,
  ###    log => 1,    # logaritmic output 
  ###  alpha => 1,
  ### output => file,
  ### encoding => utf8,
  ### ignorexml => 1,
  ### ignorecase => 1}

  my %opt = (from => 'file', ignorecase => 0, ignorexml => 0, encoding => "latin1");
  %opt = (%opt , %{shift(@_)}) if ref($_[0]) eq "HASH";

  local $\ = "\n";                    # set output record separator

  my $P="(?:[,;:?!]|[.]+|[-]+)";      # pontuacao a contar
  my $A="[A-ZÒ—a-z·‡„‚‰ÁÈËÍÎÌÔÛÚıÙˆ˙˘˚¸¡¿√¬ƒ«…» ÀÕœ”“’‘÷⁄Ÿ€‹_]";
  my $I="[ \"(){}+*=<>\250\256\257\277\253\273]"; # car. a  ignorar
  my %oco=();
  my $tot=0;

  if ($opt{from} eq 'string') {
    my (@str) = (@_);
    for (@str) {
      $_ = lc if $opt{ignorecase};
      s/<[^>]+>//g if $opt{ignorexml};
      for (/($A+(?:['-]$A+)*|$P)/g) { $oco{$_}++; $tot++ }
    }
  } else {
    my (@file) = (@_);
    for(@file) {
      open F,"< $_" or die "cant open $_: $!";
      binmode(F, ":utf8") if $opt{encoding} =~ /utf8/i ;
      while (<F>) {
	$_ = lc if $opt{ignorecase};
	s/<[^>]+>//g if $opt{ignorexml};
	for (/($A+(?:['-]$A+)*|$P)/g) { $oco{$_}++;  $tot++}
      }
      close F;
    }
  }

  if ($opt{log}){
    print "total = $tot\n";
    _setmax($tot);
    _setmax($opt{log}) if($opt{log} > 1);
    for (keys %oco){
      $oco{$_}=_logit($oco{$_});
    }
  }

  if ($opt{num}) { # imprime por ordem de quantidade de ocorrencias

    # TODO: n„o È port·vel
    if (defined $opt{output}) {
      open SORT,"| sort -nr > $opt{output}"
    } else {
      open SORT,"| sort -nr"
    }

    for my $i (keys %oco) {
      print SORT "$oco{$i} $i"
    }
    close SORT;

  } elsif ($opt{alpha}) { # imprime ordenado alfabeticamente

    if (defined $opt{output}) {
      open SORT ,"> $opt{output}";
      for my $i (sort keys %oco ) {
	print SORT  "$i $oco{$i}";
      }
    } else {
      binmode STDOUT, ":utf8" if $opt{encoding};
      for my $i (sort keys %oco ) {
	print  "$i $oco{$i}";
      }
    }
  } else {
    return (%oco)
  }
}

### syllabs, and accents

sub accent {
  local $/ = "";           # input record separator=1 or more empty lines
  my $p=shift;
  $p =~ s/(\w+)/ wordaccent($1) /ge;
  $p
}

sub wordaccent {
  my $p = syllable($_[0]);
  my $flag = $_[1] or 0; # 0 (default) => use : after vowel; 1 => use " before syllable
  for ($p) {
    s{(\w*$acento)}{"$1}i             or  # word with an accent character
#      s{(\w*)([ua])(ir)$}{$1$2|"$3}i  or  # word ending with air uir
      s{(\w*([zlr]|[iu]s?|um))$}{"$1}i   or  # word ending with z l r i u is us
      s{(\w+\|\w+)$}{"$1}             or  # accent in 2 syllable frm the end
      s{(\w)}{"$1};                       # accent in the only syllable

    if(!$flag){
      # s{"(([qg]u|$consoante)*($vogal|[yw]))}{$1:}i; # accent in the 1.st vowel
      # bugfix: quo|ti|"dia|no => quo|ti|dia:|no; op|"Á„o => op|Á„:o
      s{"(([qg]u|$consoante)*([i]$vogal|$vogal|[yw]))}{$1:}i; # accent in the 1.st vowel
      s{:($acento)}{$1:}i;                         # mv accent after accents
      s{"}{}g;
    }

  }
  $p
}

my %syl = (
   20 => " -.!?:;",
   10 => "bÁdfgjkpqtv",
   8 => "sc",
   7 => "m",
   6 => "lzx",
   5 => "nr",
   4 => "h",
   3 => "wy",
   2 => "eao·ÈÌÛ˙Ù‚Í˚‡„ı‰ÎÔˆ¸",
   1 => "iu",
   breakpair =>
      #"ie|ia|io|ee|oo|oa|sl|sm|sn|sc|sr|rn|bc|lr|lz|bd|bj|bg|bq|bt|bv|pt|pc|dj|pÁ|ln|nr|mn|tp|bf|bp",
      "sl|sm|sn|sc|sr|rn|bc|lr|lz|bd|bj|bg|bq|bt|bv|pt|pc|dj|pÁ|ln|nr|mn|tp|bf|bp|xc|sÁ|ss|rr",
	# dÌgrafos que se separam sempre: xc, sÁ, ss, rr, sc.
  );

my %spri = ();

for my $pri (grep(/\d/, keys %syl)){
  for(split(//,$syl{$pri})) { $spri{$_} = $pri}}

(my $sylseppair= $syl{breakpair}) =~ s/(\w)(\w)/(\?<=($1))(\?=($2))/g;

sub syllable{
  my $p=shift;

  for($p){
    s/$sylseppair/|/g;
    s{(\w)(?=(\w)(\w))}
      {if($spri{lc($1)}<$spri{lc($2)} && $spri{lc($2)}>=$spri{lc($3)}){"$1|"}
       else{$1}
      }ge;

    s{([a])(i[ru])$}{$1|$2}i;   #ditongos and friends

    #s{([ioeÍ])([aoe])}{$1|$2}ig; # not this simple
    s{(?<!^h)([ioeÍ])([e])}{$1|$2}ig;   #
    s{([ioeÍÈ])([ao])}{$1|$2}ig;    # la|go|a; di|a; ru|bÈ|o|la; nÈ|on; au|rÈ|o|la

    s{([^qg]u)(ai|ou|a)}{$1|$2}i;   # BUGFIX:  [^q]: qu|a|se => qua|se
    s{([^qgc]u)(i|ei|iu|ir|$acento|e)}{$1|$2}i; # continu|e
    s{([lpt]u)\|(i)(?=\|[ao])}{$1$2}ig;  # a|le|lui|a ta|pui|a con|lui|o
    s{([^q]u)(o)}{$1|$2}i;      # quo|ta; v·cu|o
    s{([aeio])($acento)}{$1|$2}i;
    s{([Ì˙Ù])($vogal)}{$1|$2}i;
    s{^a(o|e)}{a|$1}i;			# a|onde; a|orta; a|erÛdromo

    # Exemplo: his|tÛ|ria
    if( m/([\w\|]*$acento[\w\|]*)\-/) {
      if ( m/([eiou])\|([aeio])\-/ ) { # palavras com hifen
        s{([eiou])\|([aeio])(?=\-)}{$1$2}ig if $1 ne $2 ; 
      }
    }
    if ( m/([\w\|]*$acento[\w\|]*)$/ ) {
      if ( m/([eiou])\|([aeio])$/ ) {
        s{([eiou])\|([aeio])$}{$1$2}ig if $1 ne $2 ;
      }
    }

    #s{([qg]u)\|([eiÌ])}{$1$2}i;

    s{rein}{re|in}ig;  # re|in|ves|tir
    s{ae}{a|e}ig; # ma|ca|en|se ; es|ma|e|cer
    s{ain}{a|in}ig;  # a|in|da con|tra|in|for|mar pa|in|Áo
    s{ao(?!s)}{a|o}ig; # ca|o|ti|ca|men|te ; ma|o|me|tis|mo != caos
    s{cue}{cu|e}ig; # ar|cu|en|se
    s{cui(?=\|?[mnr])}{cu|i}ig; #
    s{cui(?=\|da\|de$)}{cu|i}ig; # pro|mis|cu|i|da|de; i|no|cu|i|da|de
    s{coi(?=[mn])}{co|i}ig; # co|in|ci|den|te;
    s{cai(?=\|?[mnd])}{ca|i}ig; # des|ca|i|de|la; des|ca|i|men|to
    s{ca\|i(?=\|?[m]$acento)}{cai}ig; # cai|m„o
    s{cu([·Û])}{cu|$1}ig; # pe|cu|·|ria va|cu|Û|me|tro
    s{ai(?=\|?[z])}{a|i}ig; # ra|iz ; en|ra|i|zar
    s{i(u\|?)n}{i|$1n}ig; # tri|un|fo
    s{i(u\|?)r}{i|$1r}ig; # di|ur|no
    s{i(u\|?)v}{i|$1v}ig; # viuvar
    s{i(u\|?)l}{i|$1l}ig; # friulano
    s{ium}{i|um}ig; # mÈdium
    s{([ta])iu}{$1i|u}ig; # multiuso , baiuca,  maiusculizar
    s{miu\|d}{mi|u|d}ig; # miudinho
    s{au\|to(?=i)}{au|to|}ig; # au|to|i|ma|gem
    s{(?<=$vogal)i\|nh(?=[ao])}{|i|nh}ig; # # ven|to|i|nha
    s{oi([mn])}{o|i$1}ig; # a|men|do|im monoinsaturado microinjecÁ„o
    s{oi\|b}{o|i|b}ig; # proibido
    s{ois(?!$)}{o|is}ig; # ma|o|is|mo ; e|go|is|ti|ca|men|te
    s{o(i\|?)s(?=$acento)}{o|$1s}ig; # ra|di|o|i|sÛ|to|po
    s{([dtm])aoi}{$1a|o|i}ig; # da|o|is|ta ; ta|o|is|ta ; ma|o|is|ta
    s{(?<=[trm])u\|i(?=\|?[tvb][oa])}{ui}ig;
    # ?: gra|tui|ti|da|de vs in|tu|i|ti|vo

    s{^gas\|tro(?!-)}{gas|tro|}ig; # gas|tro|in|tes|ti|nal ; gas|tro-in|tes|ti|nal
    s{^fais}{fa|is}ig; # faiscar | faiscaÁ„o
    s{^hie}{hi|e}ig; # hi|e|na ; hi|e|rar|ca
    s{^ciu}{ci|u}ig; # ci|u|men|to
    s{(?<=^al\|ca)\|i}{i}ig; # al|cai|de
    s{(?<=^an\|ti)(p)\|?}{|$1}ig; # anti
    s{(?<=^an\|ti)(\-p)\|?}{$1}ig; # anti
    s{(?<=^neu\|ro)p\|}{|p}ig; # neu|ro|psi|cÛ|lo|go
    s{(?<=^pa\|ra)p\|}{|p}ig; # pa|ra|psi|cÛ|lo|go
    s{(?<=^ne\|)op\|}{o|p}ig; # neopsicadÈlico
    s{^re(?=[i]\|?[md])}{re|}ig; # re|i|dra|ta|Á„o
    s{^re(?=i\|n[iÌ]\|c)}{re|}ig; # re|i|ni|ci|ar
    s{^re(?=i\|nau\|g)}{re|}ig; # re|i|nau|gu|rar
    s{^re(?=[u]\|?[ntsr])}{re|}ig; # re|u|so
    s{(?<=^vi\|de\|)o($vogal)}{o|$1}ig; # vi|de|o|a|ma|dor

    s{^su\|b(?!$vogal)}{sub|}ig;
    s{(?<=[\|\-])su\|b(?!$vogal)}{sub|}ig;
    s{^sub\|l(?=i\|?m)}{su|bl}ig; # su|bli|mar (excepÁ„o, compostas: sub|li|mi|nar sub|li|mi|te)
    s{(?<=\|)sub\|l(?=i\|?m)}{su|bl}ig;
    s{^sub\|l(?=i\|?nh)}{su|bl}ig;  # (excepÁ„o: sublinha)
    s{(?<=\|)sub\|l(?=i\|?nh)}{su|bl}ig;
    s{^sub\|s(?=\|?$vogal)}{sub|s}ig;
    s{(?<=\|)sub\|s(?=\|?$vogal)}{sub|s}ig;
    s{^sub\|s(?=\|?$consoante)}{subs|}ig;
    s{(?<=\|)sub\|s(?=\|?$consoante)}{subs|}ig;

    s{so\|bs}{sobs}ig; # de|sobs|tru|ir

    s{(?<=\|)trai(?=\|d)}{tra|i}ig;  # re|tra|i|da|men|te ; des|con|tra|i|da|men|te

    s{^e\|cze}{ec|ze}ig;  # ec|ze|ma

    s{^ex\|tra(?=$vogal)}{ex|tra|}ig; # ex|tra|or|di|na|ri|a|men|te

    s{u\|i$}{ui}ig; # institui ; chui ; 
    s{\|?Ûi([ao])$}{Ûi|$1}ig; # jÛia clarabÛia
    s{ei([oa])(?=$|\-)}{ei|$1}ig; # ma|rÈ-chei|a mei|a-ir|m„ meio

    s{^a\|([bd])([svqnmgfz])($vogal)}{a$1|$2$3}ig;  # ab|sin|to
    s{(?<=\|)a\|([bd])([svqnmgfz])($vogal)}{a$1|$2$3}ig;  # re|ab|sor|Á„o
    s{^a\|(b)(r)(o)(?=\|g)}{a$1|$2$3}ig;  # ab|ro|ga|Á„o
    s{^a\|([bd])([s])\|?($consoante)}{a$1$2|$3}ig;  # abs|trac|to
    s{^o\|([bd])([svqnmgfz])($vogal)}{o$1|$2$3}ig;  # ob|ser|var
    s{^o\|([bd])([s])\|?($consoante)}{o$1$2|$3}ig;  # obs|tru|ir
    s{([qg]u)\|([aeiÌ])}{$1$2}i;
    s{([qg]u)\|([o])$}{$1$2}i;  # ambÌguo; contÌguo

    s{^($consoante)\|}{$1}i;
    #s{Ím$}{Í|_nhem}i;      # removido apÛs reuni„o do P-Pal a 2010-06-01

    s{tun\|gs}{tungs}ig;  # tungstÈnio

    s{p\|s$}{ps}i; # excepÁ„o de "ps" como breakpair
    s{(^p|\-p)\|s([iÌ])}{$1s$2}i; # excepÁ„o de "ps" como breakpair => mÈ|di|co-psi|co|lÛ|gi|co

    s{s\|s$}{ss}i; # excepÁ„o de "ss" como breakpair => fitness

    s{\|\|}{\|}g;
  }
  $p
}

# carregar ficheiros necess·rios para transcriÁ„o fonÈtica
sub initPhon
{
	our $dic = carregaDicionario($ptpho);
	our $no_accented = chargeNoAccented($naoacentuadas);
}

# transcriÁ„o fonÈtica
sub toPhon {
  my $word = shift;
  my $prefix = undef;
  my $res = undef;
  $word = lc($word);

  unless ($word =~ /,/) {
    $res = gfdict($word,$dic); #$dic->{$word};
    #             $res = "$dic->{$1}S" if(!$res &&  $word =~ /(.*)s$/ );
    
    unless ($res || length($word)<3) {

      $prefix = $word;
      do {
	$prefix =~ s{\*$}{}g;
	$prefix =~ s{.$}{*};
	$res = $dic->{$prefix};
      } until ($res || $prefix =~ m!^\w\*! );
    }

    if (defined($prefix)) {
      if ($res) {
	$prefix =~ s{\*$}{}g;
	$res    =~ s{\*$}{}g;
	$word =~ s/^$prefix/$res/;
	undef($res);
      }
    }
  }
  if ($res) {
    if ($res =~ /^!/) {
      $res = toPhon2($');
    }
  } elsif ($no_accented->{$word}) {
    $res = Lingua::PT::PLN::Words2Sampa::run($word, 0); # debug = 0
  } else {
    $res = toPhon2($word);
  }
  return $res;
}

sub toPhon2
{
  my $word = shift;
  my $t = wordaccent($word, 1);
  $t =~ s/\|//g;
  return Lingua::PT::PLN::Words2Sampa::run($t, 0); # debug = 0
}

sub chargeNoAccented {
  my $file = shift;
  my $dic;
  open F, $file or die ("cannot open dictionary file: $!");
  while(<F>) {
    chomp;
    $dic->{$_}++;
  }
  close F;
  return $dic;
}

sub carregaDicionario {
  my $file = shift;
  my $dic;
  open F, $file or die ("cannot open dicionary file: $!");
  while(<F>) {
    chomp;
    my ($a,$b) = split /=/;
    $dic->{$a}=$b;
  }
  close F;
  return $dic;
}

sub gfdict{ 
  my ($word,$dic) = @_;
  return "" unless ($word =~ /\w/);
  my $res = $dic->{$word};
  unless($res){ $res = $dic->{$1} if( $word =~ /^(.*)s$/ );
                return "" unless ($res);
                if($res =~ /^!/) {$res .= "s"}
                else             {$res .= "S"}
  }
  $res;
}

sub compara {
  # ordena pela lista de palavras invertida
  join(" ", reverse(split(" ",$a))) cmp join(" ", reverse(split(" ",$b)));
}

sub compacta {
  my $s;
  my $p = shift;
  my $r = $p;
  my $q = $names{$p};
  while ($s = shift) {
    if ($s =~ (/^(.+) $p/))
      {
	$r = "($1) $r" ;
	$q += $names{$s};
      }
    else
      {
	print "$r - $q";
	$r = $s;
	$q = $names{$s};
      }
    $p=$s;
  }
  print "$r - $q";
}

my %savit_p = ();
my $savit_n = 0;

sub _savit {
  my $a = shift;
  $savit_p{++$savit_n} = $a ;
  " __MARCA__$savit_n "
}

sub _loadit {
  my $a = shift;
  $a =~ s/ ?__MARCA__(\d+) ?/$savit_p{$1}/g;
  $savit_n = 0;
  $a;
}

1;

#sub setlogmax{
# $maxlog = shift;
# $magicF=$maxlog/log($lmax);
###  print "Debud .... Maxlog=$maxlog; magic=$magicF\n";
#}

sub _setmax{
 $lmax = shift;
 $magicF=$maxlog/log($lmax);
##  print "Debud .... Max=$lmax; magic=$magicF\n";
}

sub _logit{
  my $n=shift;
  return 0 unless $n;
##  print STDERR "...$n,", log($n*$magicF) ,"\n" ;
  log($n)*$magicF
}

1;

__END__

$lm='[a-z·ÈÌÛ˙‚ÍÙ‡„ıÁ¸ˆÒ]';                      # letra minuscula
$lM='[A-Z¡…Õ”⁄¬ ‘¿√’«‹÷—]';                      # letra Maiuscula
$l1='[A-Z¡…Õ”⁄¬ ‘¿√’«‹÷—a-z·ÈÌÛ˙‚ÍÙ‡„ıÁ¸ˆÒ0-9]'; # letra e numero
$c1='[^ªa-z·ÈÌÛ˙‚Í‡,;?!)]';

=encoding ISO-8859-1

=head1 NAME

Lingua::PT::PLN - Perl extension for NLP of the Portuguese Language

=head1 SYNOPSIS

  use Lingua::PT::PLN;

  # occurrence counter
  %o = oco("file");
  oco({num=>1,output=>"outfile"},"file");

  $p = accent($phrase);        ## mark word accent of all words

  $w = syllable($word);		# get syllables
  $w = wordaccent($word);	# get word accent with : after vowel (default)
  $w = wordaccent($word, 1);	# get word accent with " before syllable (standard)

  initPhon;			# initializes Phonetic dictionary (adds manual corrections)
  $w = toPhon($word);		# get phonetic transcription

=head1 DESCRIPTION

This is a module for Natural Language Processing of the Portuguese.

Because you are processing Portuguese, you must use a correct locale.

=head2 Occurrence counting: C<oco>

Counts word occurrence from a string or a set of files. Returns an
hash with the information or creates a sorted file with the results.

This function takes optionally as first argument an hash of options
where you can specify:

=over 4

=item num => 1

means the output should be sorted by ocurrence number;

=item alpha => 1

mean the output should be sorted lexicographically

=item output => "f"

means the output will be written to the file "f";

=item from => "string"

means that next argument (after the option hash) is a string which
should be used as input for the function.

=item from => "file"

means that remaining arguments to the function are filenames which
should be used as input for the function. This is the default option.
  
=item encoding => "utf8"

To force UTF8 encoding (default latin1)

=item ignorexml => 1

XML tags are striped.

=item ignorecase => 1

All words are lower-cased.

=item log => 1

to obtain logaritmic output. Output values are between 0..log(1000000) 
or (0..13.85).

  log => 20    -- to obtain values between 0 and 20

=back

Examples:

  oco({num=>1,output=>"f"}, "f1","f2")
  # sort by occurrence
  # store output on file "f"
  # process files "f1" and "f2"

  oco({alpha=>1,output=>"f"}, "f1","f2")
  # sort lexicographically
  # store output on file "f"
  # process files "f1" and "f2"

  %oc = oco("f1","f2")
  # return a hash with the occurrences
  # use "f1" and "f2" as input files

  %oc = oco( {from=>"string"},"text in a string")
  # use a string as input
  # return a hash with the occurrences

=head2 C<syllable>

  my $sylls = syllable( $word )

Returns the word with the syllables separated by "|"

=head2 accent

  my $accent = accent( $phrase )

Returns the phrase with the syllables separated by "|" and accents marked with
the charater ":".

=head2 wordaccent

Retuns the word splited into syllables and with the accent character marked.

=head2 compacta

=head2 compara

=head2 initPhon

=head2 toPhon

=head2 carregaDicionario

=head2 chargeNoAccented

=head2 gfdict

=head2 toPhon2

=head1 AUTHOR

Projecto Natura (http://natura.di.uminho.pt)

Alberto Simoes (albie@alfarrabio.di.uminho.pt)

JosÈ Jo„o Almeida (jj@di.uminho.pt)

Paulo Rocha (paulo.rocha@di.uminho.pt)

=head1 SEE ALSO

Lingua::PT::PLNbase(3pm),
perl(1),
cqp(1),

=cut
