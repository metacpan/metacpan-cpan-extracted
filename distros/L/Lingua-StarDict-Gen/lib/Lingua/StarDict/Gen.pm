package Lingua::StarDict::Gen;

use warnings;
use strict;
use Data::Dumper;
use locale;
use Encode;
use utf8;
use File::Spec::Functions;
#use POSIX qw(locale_h);
#setlocale(LC_ALL,"C");

$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;

our $VERSION = '0.10';

my $nome; my %dic; 

sub carregaDic { &loadDict; }

sub loadDict {
  my %opt =(type=> "default");
  local $/;
  if(ref($_[0]) eq "HASH") {%opt = (%opt , %{shift(@_)}) } ;

  if ($opt{type} eq "default"){ $/ = "\n"; }
  if ($opt{type} eq "term")   { $/ = "";   }

  my $file = shift;
  my %dic;
  open IN,"<$file" or die "Can load $file\n";
  while (<IN>) {
      chomp;
      if (m!^%enc(oding)?\s+([a-zA-Z0-9-]+)!) {
         binmode IN, ":$2";
         next
      } elsif ($opt{type} eq "term") {
        $opt{lang} = $1 if(!$opt{lang} &&  m((\w+)));

        my $inf={};
        my @ls = split (/\n(?=\S)/,$_);  
        for (@ls){
          if(/(\w+)\s+(.*)/s){ push( @{$inf->{$1}}, split (/\s*[;,]\s*/,$2));} 
        }
        for(@{$inf->{$opt{lang}}}){ 
          $dic{$_} = $inf;
        }
      } elsif ($opt{type} eq "default" && /(.*?)\s*\{\s*(.*?)\s*\}/) {
        my @palavras = split (/\s*;\s*/,$2);  
        $dic{$1} = [@palavras];
      }
  }
  close IN;
  \%dic
}

sub mostraDic { &showDict; }

sub showDict {
    $nome = shift;
    %dic = %{$nome};
    for my $chave (sort (keys %dic)) {
        for (@{$dic{$chave}}) {
            print "$chave -> $_\n";
        }
    }
}

sub escreveDic { &writeDict; }


sub writeDict {
    my $hash= shift;
    my $dic = shift;
    my $dirpath=shift;
    my $d ;  ## install dic directory
    my $s='/';
    if(    $^O eq "linux")  {$d= "/usr/share/stardict/dic/" }
    elsif( $^O eq "darwin") {$d= "/opt/gtk/share/stardict/dic/" }
    elsif( $^O eq "MSWin32"){$d= "$ENV{ProgramFiles}\\stardict\\dic\\";$s="\\"}
    $dirpath ||= "";
    $dirpath ||= $d if -d $d;
    $dirpath ||= "/usr/local/share/stardict/dic/" if -d "/usr/local/share/stardict/dic/";
    my $finalpath= catfile($dirpath,$dic);
    unless(-d $finalpath){
      mkdir($finalpath,0755) or die "Cant create directory $finalpath\n";
    }
    my $finalpath2= catfile($finalpath,$dic);

    open DICT,">:raw:utf8","$finalpath2.dict" or die ("Cant create $dic.dict\n");
    open IDX, ">:raw"     ,"$finalpath2.idx"  or die ("Cant create $dic.idx\n");
    open IFO, ">:raw"     ,"$finalpath2.ifo"  or die ("Cant create $dic.ifo\n");

    my $byteCount = 0;
    my @keys =();
### { no locale; @keys = sort (keys %{$hash}); }
    @keys = sort {_stardict_strcmp($a,$b)} (keys %{$hash});                                   
    for my $chave (@keys) {
        my $posInicial = $byteCount;
        my $word8 = $chave;
        $word8 = encode_utf8($word8) unless utf8::is_utf8($chave);
        { use bytes; print IDX pack('a*x',$word8); }

        print IDX pack('N',$byteCount);
        ###  print "$chave \@ $byteCount\n";
        print DICT "$word8\n";
        $byteCount += (bytes::length($word8) + 1);

        if(ref($hash->{$chave}) eq "ARRAY"){
           for (@{$hash->{$chave}}) {
              my $b=$_;
              if(ref $_){ $b= _dumperpp(Dumper($b)); }
              print DICT "\t$b\n";
              $byteCount += (_len2($b) + 2);
           } }
        elsif(ref($hash->{$chave})) {
           my $a= _dumperpp(Dumper($hash->{$chave}));
           ###  print "DEBUG: $chave\n";
           print DICT "  $a\n";
           $byteCount += (_len2($a) +3); }
        else {
           my $a=$hash->{$chave};
           $a =~ s/\s*$//;
           $a =~ s/\n/\n\t/g;
           ###  print "DEBUG: $chave\n\t$a\n";
           print DICT "\t$a\n";
           $byteCount += (_len2($a) +2); 
        }
        print DICT "\n\n";
        $byteCount +=2;
        print IDX pack('N',$byteCount-$posInicial);
        ###  print "length: ",($byteCount-$posInicial),"\n";
    }
    my $nword = scalar (keys %{$hash});
    my @t= gmtime(time);
    print IFO "StarDict's dict ifo file\n";
    print IFO "version=2.4.2\n";
    print IFO "wordcount=$nword\n";
    print IFO "bookname=$dic\n";
    ## print IFO "dictfilesize=$byteCount\n";
    print IFO "idxfilesize=", tell(IDX),"\n";
    print IFO "date=", 1900+$t[5], "-" , $t[4]+1 , "-" , $t[3],"\n";
    if($^O eq "MSWin32"){ print IFO "sametypesequence=m\n";}
    else                { print IFO "sametypesequence=x\n";}
    close(IFO);
    close(DICT);
    close(IDX);
}

sub _len2{ 
   my $string = shift;
   $string = encode_utf8($string) unless utf8::is_utf8($string);
   bytes::length($string) ;
}
#sub len2{ do { length($_[0]) } }

sub _dumperpp{
   my $a = shift;
   $a =~ s/.*'_NAME_' .*\n// ;
#   $a =~ s/\$VAR\d*\s*=(\s|[\{\[])*//;
   $a =~ s/^(\s|[\{\[])*//;
   $a =~ s/[\}\]]?\s*$//;
   ## $a =~ s/\n        /\n\t/g;
   $a =~ s/\s*(\[|\]|\{|\}),?\s*\n/\n/g;
   $a =~ s/\\x\{(.*?)\}/chr(hex("$1"))/ge;
   $a =~ s/'(.*?)'/$1/g;
   $a =~ s/"(.*?)"/$1/g;
   $a;
}

sub _g_ascii_strcasecmp { # pure perl re-implementation of g_ascii_strcasecmp
  my $s1 = shift;
  my $s2 = shift;
  no locale;
  $s1=~s/([A-Z])/lc($1)/ge;
  $s2=~s/([A-Z])/lc($1)/ge;
  while (length($s1) || length($s2))
  {
    return -1 if length($s1)==0;
    return 1 if length($s2)==0;
    $s1=~s/^(.)//;
    my $c1 = $1;
    $s2=~s/^(.)//;
    my $c2 = $1;
    return ord($c1)-ord($c2) if $c1 ne $c2;
  }
  return 0;
}

sub _strcmp { # pure perl re-implementation of strcmp
  my $s1 = shift;
  my $s2 = shift;
  no locale;
  while (length($s1) || length($s2)) {
    return -1 if length($s1)==0;
    return 1 if length($s2)==0;
    $s1=~s/^(.)//;
    my $c1 = $1;
    $s2=~s/^(.)//;
    my $c2 = $1;
    return ord($c1)-ord($c2) if $c1 ne $c2;
  }
  return 0;
}

sub _stardict_strcmp { # pure perl re-implementation of stardict_strcmp
  my $s1 = shift;
  my $s2 = shift;
  
  my $i = _g_ascii_strcasecmp($s1, $s2);
  return $i if $i;
  return _strcmp($s1,$s2);
}


1;

=encoding utf8

=head1 NAME

Lingua::StarDict::Gen - Stardict dictionary generator 

=head1 SYNOPSIS

  use Lingua::StarDict::Gen;

  $dic = { word1 => ...
           word2 => ...
         }

  Lingua::StarDict::Gen::writeDict($dic,"dicname" [,"dirpath"]);
  Lingua::StarDict::Gen::escreveDic($dic,"dicname" [,"dirpath"]);

  $dic=Lingua::StarDict::Gen::loadDict("file");
  $dic=Lingua::StarDict::Gen::carregaDic("file");

=head1 DESCRIPTION

This module generates StarDict dictionaries from HASH references (function C<escreveDic>).

This module also imports a simple dictionary (lines with C<word {def1; def2...}>)(function
C<carragaDic>).


=head1 ABSTRACT

C<Lingua::StarDict::Gen> is a perl module for building Stardict 
dictionaries from perl Hash.

Also included perl script for making stardicts form term-format and
thesaurus-format.

=head1 FUNCTIONS

=head2 writeDict

=head2 escreveDic

  Lingua::StarDict::Gen::writeDict($dic,"dicname");
  Lingua::StarDict::Gen::writeDict($dic,"dicname", dir);

Write the necessary files StarDict files for dictionary in $dic HASH reference.

C<dir> is the directory where the StarDict files are written.

If no C<dir> is provided,  Lingua::StarDict::Gen will try to write it in
C</usr/share/stardict/dic/...> (the default path for StarDict dictionaries).
In this case the dictionary will be automatically installed.


=head2 loadDict

=head2 carregaDic

This function loads a simple dictionary to a HASH reference.

  $dic=Lingua::StarDict::Gen::loadDict("file");

Where file has the following sintax:

  word{def 1; def 2;... ;def n}

Example (default format):

 %encoding utf8
 cat{gato; tareco; animal com quatros patas e mia}
 dog{...}

Example2 (terminology format):

 %encoding utf8

 EN cat ; feline
 PT gato ; tareco
 DEF animal com 4 patas e que mia

 EN house; building; appartment 
 PT house
 FR maison
 ...

In this case we must say the type used:

  $dic=Lingua::StarDict::Gen::loadDict({type=>"term"},"file");

or even specify the language:

  $dic=Lingua::StarDict::Gen::loadDict(
        {type=>"term", lang=>"PT"},"file");

See also the script C<term2stardic> in the destribution.

=head2 mostraDic

=head2 showDict

 showDict($hash);

Prints to stdio the information in the hash in the form

 word -> definition

=head1 Authors

José João Almeida

Alberto Simões

Paulo Silva

Paulo Soares

Nicolav Shaplov

=head1 SEE ALSO

stardict

perl

wiktionary-export/trunk/StarDict

=head1 COPYRIGHT & LICENSE

Copyright 2008 J.Joao, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Lingua::StarDict::Gen
