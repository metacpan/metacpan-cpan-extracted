# say to emacs, I want -*- cperl -*- mode
package Lingua::PT::Speaker;

use strict;

use Lingua::PT::PLN;

use Lingua::PT::Speaker::Numbers;
use Lingua::PT::Speaker::Words2Sampa;
use Lingua::PT::Speaker::Prosody;
use Lingua::PT::Speaker::AdjWords;
use Lingua::PT::Speaker::Specials;

require Exporter;

our @ISA = qw(Exporter AutoLoader);
our @EXPORT = qw(&speak &toPhon);

our $VERSION = "0.12";

use locale;
$ENV{LC_LANG}='PT_pt';

$INC{'Lingua/PT/Speaker.pm'} =~ m!/Speaker\.pm$!;
our $ptpho = "$`/Speaker/ptpho";
our $naoacentuadas = "$`/Speaker/nao_acentuadas";

our $debug;

BEGIN{ $debug = 0;}

our $vg = '[6AEIOUaeiouyw@]';
our $con = '[BCDFGHJKLMNPQRSTVWXYZÇbcdfghjklmnpqrstvxzç]';


=head1 NAME

Lingua::PT::Speaker - perl extension text to speech of Portuguese text

=head1 SYNOPSIS

  use Lingua::PT::Speaker;

  $pt1 = '/usr/lib/mbrola/pt1/pt1';

  Lingua::PT::speaker::debug() if $debug;

  my $tmp="/tmp/_$$";

  $/="" if  $l;
  while($line = <>){
     speak({output => "$tmp.pho"}, $line);
     system("mbrola -t $t $pt1 $tmp.pho $tmp.wav; play $tmp.wav"); 
  }

=head1 DESCRIPTION


=head2 EXPORT


=head1 AUTHOR

J.Joao Almeida, jj@di.uminho.pt

Alberto Simões, albie@alfarrabio.di.uminho.pt

=head1 SEE ALSO

Lingua::PT::PLN

mbrola

mbrola/pt1

perl(1).

=cut      

sub debug {
  $debug = ! $debug ; 
}

sub speak {
  my $text = shift;
  my %opt = (output => "_.pho");

  if(ref($text) eq "HASH"){
     %opt= (%opt, %$text);
     $text = shift;
  }

  $text.="." unless $text=~/[!.?]$/;

  our $dic = carregaDicionario($ptpho);
  our $no_accented = chargeNoAccented($naoacentuadas);

  open PHO, "> $opt{output}";

  $text =~ s{_\((.*?)\)_}{Lingua::PT::Speaker::Numbers::math($1)}ge;
    print STDERR "1 {{$text}}\n" if $debug ;
  $text =~ s{(\w+\@(\w+\.)+\w+)}{Lingua::PT::Speaker::Numbers::email($1)}ge;
    print STDERR "2\n" if $debug ;
  $text =~ s{(((((ht|f)tp://)|(www\.))(\w+\.)+\w+)(/\w+)*)}{Lingua::PT::Speaker::Numbers::email($1)}ge;
    print STDERR "3\n" if $debug ;
  $text =~ s{(\d+[ºª])}{Lingua::PT::Speaker::Numbers::ordinais($1)}ge;
    print STDERR "4\n" if $debug ;
  $text =~ s{(\d+(\.\d+)?)}{Lingua::PT::Speaker::Numbers::number($1)}ge;
    print STDERR "5\n" if $debug ;
  $text =~ s{\b([B-DF-HJ-NP-TV-Z]{1,7})\b}{Lingua::PT::Speaker::Numbers::sigla($1)}ge;

  if ($opt{special}) {
    my $special;
    for $special (@{$opt{special}}) {
      $text=Lingua::PT::Speaker::Specials::txtspecials($special,$text)
    }
  }

#  $text=~s{;}{,,}g;

  print STDERR  "6 !$text" if $debug ;
  $text = Lingua::PT::Speaker::Numbers::nontext($text);
  print STDERR "7\n" if $debug ;
  foreach( map{type_sentence($_) } mysentences($text) ) {
    @{$_->{words}} = words($_->{sentence});
    print STDERR "8 before toPhon\n" if $debug ;
    @{$_->{phon}}  = map {toPhon($_,$dic,$no_accented)} @{$_->{words}} ;
    print STDERR "9 after toPhon / ttf:",join("+",@{$_->{phon}}),"\n" if $debug;
    print STDERR "10 before AdjWords::merge\n" if $debug ;
    my $t1= Lingua::PT::Speaker::AdjWords::merge(join("/",@{$_->{phon}}));
    if ($opt{special}) {
      my $special;
      for $special (@{$opt{special}}) {
        $t1=Lingua::PT::Speaker::Specials::phospecials($special,$t1)
      }
    }
    my @phonemas = (split( /\s+/, $t1), $_->{dot});
    print STDERR "11 after merge:",(join("+",@phonemas)),"\n" if $debug;
    print STDERR "12 after prosod:",Lingua::PT::Speaker::Prosody::a( join(" ",@phonemas)),"\n" if $debug;
    print PHO Lingua::PT::Speaker::Prosody::a( join(" ",@phonemas)),"\n" ;

  }

  close PHO;

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


sub toPhon {
  my ($word,$dic,$no_accented) = @_;
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
    $res = Lingua::PT::Speaker::Words2Sampa::run($word, $debug);
  } else {
    $res = toPhon2($word);
  }
  return $res;
}

sub toPhon2 {
  my $word = shift;
  print STDERR "9.1 Before silabas: $word\n" if $debug;
  my $t = join "", silabas($word);
  print STDERR "9.2 After silabas: $t\n" if $debug;
  print STDERR "9.3 before wors2sampa\n" if $debug;
  return Lingua::PT::Speaker::Words2Sampa::run($t, $debug);
}

sub words {
  my $sentence = shift;
  return grep {$_ !~ /^\s*$/} split(/(\s|,|\.|\?)/, $sentence);
}

sub type_sentence {
  my $sentence = shift;
  my $dots = '[.!?:;]+';
  my $dot;
  $sentence =~ /($dots)$/;
  ($sentence,$dot) = ($`,$1);
  return {
	  sentence => $sentence,
	  dot => $dot
	 }
}

sub mysentences {
  my $text = shift;
  my $dots = '[.!?:;]+';
  my @sentences = split(/($dots)/, $text);
  my @retval;

  my $word;
  pop @sentences if (@sentences % 2);

  while($word = shift @sentences) {
    $word.=shift @sentences;
    $word=~s/\n/ /g;
    $word=~s/(^\s+|\s+$)//g;
    $word=~s/\s\s+/ /g;
    push @retval, $word if $word;
  }
  return @retval;
}

sub silabas {
  my $word = shift;
  return split '\|', wordaccent($word);
}

__END__
