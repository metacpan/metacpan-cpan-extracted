# Korean Transliterator Generator

# $Id: TransliteratorGenerator.pm,v 1.7 2007/11/29 14:25:31 you Exp $

package Encode::Korean::TransliteratorGenerator;

our $VERSION = do { q$Revision: 1.7 $ =~ /\d+\.(\d+)/; sprintf "%.2f", $1 / 100  };

use 5.008008;
use strict;
use warnings;

#  == CONSTANTS ==
my $NotFound = '-1';

my $CamelCase = 0;
my $GREEDY_SEP =1;
my $SMART_SEP =  2;

my %MODE = (
   'CamelCase' => $CamelCase,
   'camel' => $CamelCase,

   'greedy_sep' => $GREEDY_SEP,
   'greedy' => $GREEDY_SEP,
   
   'smart_sep' => $SMART_SEP,
   'smart' => $SMART_SEP
);

# == CONSTRUCTOR ==
sub new {
   my ($class) = @_;
   my $self = {
      CONSONANTS => [],
      VOWELS => [],
      EL => undef,
      ELL => undef,
      NAUGHT => undef,
      SEP => undef,
      ENMODE => [],
      DEMODE => [],
      HEAD => [],  
      BODY => [],
      FOOT => [],
      HEADMAP => {},
      BODYMAP => {},
      FOOTMAP => {}
   };
   
   bless $self, $class;
   return $self;
}

# == METHODS ==
# accessor
sub consonants {
   my $self = shift;
   if(@_) { 
      @{ $self->{CONSONANTS} } = @_;
      $self->head(@_);
      @ { $self->{FOOT} } = (
         '',                                                      # NULL
         $self->{CONSONANTS}->[0],                                # kiyeok (ㄱ)
         $self->{CONSONANTS}->[1],                                # ssangkiyeok (ㄲ)
         $self->{CONSONANTS}->[0] . $self->{CONSONANTS}->[9],     # kiyeok sios (ㄳ)
         $self->{CONSONANTS}->[2],                                # nieun (ㄴ)
         $self->{CONSONANTS}->[2] . $self->{CONSONANTS}->[12],    # nieun cieuc (ㄵ)
         $self->{CONSONANTS}->[2] . $self->{CONSONANTS}->[18],    # nieun hieuh (ㄶ)
         $self->{CONSONANTS}->[3],                                # tikeut (ㄷ)
         $self->{CONSONANTS}->[5],                                # rieul (ㄹ)
         $self->{CONSONANTS}->[5] . $self->{CONSONANTS}->[0],     # rieul kiyeok (ㄺ)
         $self->{CONSONANTS}->[5] . $self->{CONSONANTS}->[6],     # rieul mieum (ㄻ)
         $self->{CONSONANTS}->[5] . $self->{CONSONANTS}->[7],     # rieul pieup (ㄼ)
         $self->{CONSONANTS}->[5] . $self->{CONSONANTS}->[9],     # rieul sios (ㄽ)
         $self->{CONSONANTS}->[5] . $self->{CONSONANTS}->[16],    # rieul thieuth (ㄾ)
         $self->{CONSONANTS}->[5] . $self->{CONSONANTS}->[17],    # rieul phieuph (ㄿ)
         $self->{CONSONANTS}->[5] . $self->{CONSONANTS}->[18],    # rieul hieuh (ㅀ)
         $self->{CONSONANTS}->[6],                                # mieum (ㅁ)
         $self->{CONSONANTS}->[7],                                # pieup (ㅂ)
         $self->{CONSONANTS}->[7] . $self->{CONSONANTS}->[9],     # pieup sios (ㅄ)
         $self->{CONSONANTS}->[9],                                # sios (ㅅ)
         $self->{CONSONANTS}->[10],                               # ssangsios (ㅆ)
         $self->{CONSONANTS}->[11],                               # ieung (ㅇ)
         $self->{CONSONANTS}->[12],                               # cieuc (ㅈ)
         $self->{CONSONANTS}->[14],                               # chieuch (ㅊ)
         $self->{CONSONANTS}->[15],                               # khieukh (ㅋ)
         $self->{CONSONANTS}->[16],                               # thieuth (ㅌ)
         $self->{CONSONANTS}->[17],                               # phieuph (ㅍ)
         $self->{CONSONANTS}->[18]                                # hieuh (ㅎ)
      );
   }
   return $self->{CONSONANTS};
}

sub head {
   my $self = shift;
   if (@_) { @{ $self->{HEAD} } = @_; }
   return $self->{HEAD};
}

sub foot {
   my $self = shift;
   if (@_) { @{ $self->{FOOT} } = @_; }
   return $self->{FOOT};
}

# accessor
sub vowels {
   my $self = shift;
   if(@_) { 
      @{ $self->{VOWELS} } = @_;
      $self->body(@_);
   }
   return $self->{VOWELS};
}

sub body {
   my $self = shift;
   if (@_) { @{ $self->{BODY} } = @_; }
   return $self->{BODY};
}



# accessor
sub el {
   my $self = shift;
   if(@_) { 
      $self->{EL} = shift;

      # Sets jongseongs with rieul
      $self->foot->[8] =   $self->{EL};                           # rieul (ㄹ)
      $self->foot->[9] =   $self->{EL} . $self->consonants->[0];  # rieul kiyeok (ㄺ)
      $self->foot->[10] =  $self->{EL} . $self->consonants->[6];  # rieul mieum (ㄻ)
      $self->foot->[11] =  $self->{EL} . $self->consonants->[7];  # rieul pieup (ㄼ)
      $self->foot->[12] =  $self->{EL} . $self->consonants->[9];  # rieul sios (ㄽ)
      $self->foot->[13] =  $self->{EL} . $self->consonants->[16]; # rieul thieuth (ㄾ)
      $self->foot->[14] =  $self->{EL} . $self->consonants->[17]; # rieul phieuph (ㄿ)
      $self->foot->[15] =  $self->{EL} . $self->consonants->[18]; # rieul hieuh (ㅀ)
   }
   return $self->{EL};
}

# accessor
sub ell {
   my $self = shift;
   if(@_) { 
      $self->{ELL} = shift;
   }
   return $self->{ELL};
}

# accessor
sub naught {
   my $self = shift;
   if(@_) { 
      $self->{NAUGHT} = shift;
      $self->{HEAD}->[11] = $self->{NAUGHT};
   }
   return $self->{NAUGHT};
}

# accessor
sub sep {
   my $self = shift;
   if(@_) { 
      $self->{SEP} = shift;
   }
   return $self->{SEP};
}

# accessor
sub enmode {
   my $self = shift;
   if(@_) { 
      $self->{ENMODE} = shift;
   }
   return $self->{ENMODE};
}

sub demode {
   my $self = shift;
   if(@_) { 
      $self->{DEMODE} = shift;
   }
   return $self->{DEMODE};
}



sub make {
   my $self = shift;

   for ( my $i=0; $i <= $#{$self->head}; ++$i ) {
      if ($self->head->[$i] eq "" && $i != 11) { 
         #printf "error: empty slot. fill the transliteration for /%s/!<br />", 
         #        encode::encode("utf8", $han_consonant[$i]); exit(1);
      }
      if (exists $self->{HEADMAP}->{$self->head->[$i]})  {
         #print_mapping_error($self::head[$i], $self::head{$self::head[$i]}, $i); 
         exit(1);
      } else {
         $self->{HEADMAP}->{$self->head->[$i]} = $i;
      };
   }

   for ( my $i=0; $i <= $#{$self->body}; ++$i ) {
      if ($self->body->[$i] eq "") { 
         #printf "error: empty slot. fill the transliteration for /%s/!<br />", 
         #        Encode::encode("utf8", $HAN_VOWEL[$i]); 
                  exit(1);
      }
      if (exists $self->{BODYMAP}->{$self->body->[$i]}) {   
         #print_mapping_error($self::BODY[$i], $self::BODY{$self::BODY[$i]}, $i); 
         exit(1);
      } else { 
         $self->{BODYMAP}->{$self->body->[$i]} = $i;
      };
      $self->{BODYMAP}->{$self->body->[$i]} = $i;
   }
   for ( my $i=0; $i <= $#{$self->foot}; ++$i ) {
      $self->{FOOTMAP}->{$self->foot->[$i]} = $i;
   }

   return $self;
}


# encode($string [,$check])
# = transliteration (romanization)
sub encode($$;$) {
    my ($obj, $str, $chk) = @_;
    my $tr = $obj->transliterate($str);
    $_[1] = '' if $chk;
    return $tr;
}

# decode($octets [,$check])
sub decode ($$;$) {
    my ($obj, $str, $chk) = @_;
    my $han = $obj->hangulize($str);
    $_[1] = '' if $chk;
    return $han;
}

# to work with encoding pragma
# cat_decode($destination, $octets, $offset, $terminator [,$check])






# = HAN TRANSLITERATOR = 
# romanizer and hangulizer

# == hangul composer and decomposer ==
#
# Unicode : 0xAC00 (가) -- 0xD7A3 (힣)
#
# foot (28 types) : 가각갂갃간갅갆갇갈갉갊갋갌갍갎갏감갑값갓갔강갖갗갘같갚갛
# body (21 types) : 가개갸걔거게겨계고과괘괴교구궈궤귀규그긔기
# head (19 types) : 가까나다따라마바빠사싸아자짜차카타파하
#


# === decompose  ===
# decomposes an unicode hangul chr into a hancode ($head, $body, $foot)
# for example, decompose('한') returns (18, 0, 4)
sub decompose {
   my $self = shift;

   my($chr) = @_;
   my $unicode = ord($chr);
   my $head = int(($unicode - 0xAC00) / (28*21));
   my $body = int(($unicode - 0xAC00 - $head*28*21) /28);
   my $foot = $unicode - 0xAC00 - $head*28*21 - $body*28;
   return ($head, $body, $foot);
}             

# === compose ===
# composes an unicode hangul chr from a hancode ($head, $body, $foot)
# for example, compose((18,0,4)) returns '한'
sub compose {
   my $self = shift;

   my($head, $body, $foot) = @_;
   my $unicode = 0xAC00 + $head*28*21 + $body*28 + $foot;
   return chr($unicode);
}



# == ROMANIZE (TRANSLITERATE) ==

# === transliterates a hangul chr (unicode hangul syllable) ===
# for example, transliterate('한') returns ('h', 'a', 'n')
sub transliterate_chr {
   my $self = shift;
   my($chr) = @_;
   my($head,$body,$foot) = $self->decompose($chr);
   #return ($self->head->[$head], $self->body->[$body], $self->foot->[$foot]);
   if ($self->enmode eq 'greedy' && $head == 11) {
      return $self->body->[$body] . $self->foot->[$foot];
   } else {
      return $self->head->[$head] . $self->body->[$body] . $self->foot->[$foot];
   }
}
sub transliterate_first_chr_of_word {
   my $self = shift;
   my($chr) = @_;
   my($head, $body, $foot) = $self->decompose ($chr);
   if ($head == 11) {
      return $self->body->[$body] . $self->foot->[$foot];
   } else {
      return $self->head->[$head] . $self->body->[$body] . $self->foot->[$foot];
   }

}

# === transliterate a hangul word ===
# Transliterates a hangul word (a string containing
# only hangul syllables)
sub transliterate_hangul_word {
   my $self = shift;
   my($word) = @_;
   my(@char) = split //, $word;
   my $tr = $self->transliterate_first_chr_of_word($char[0]);
   for (my $i=1; $i <= $#char; ++$i) {
      if ($MODE{$self->enmode} == $GREEDY_SEP) {
         $tr = $tr . $self->sep . $self->transliterate_chr($char[$i]);
      } else {
         $tr = $tr . $self->transliterate_chr($char[$i]);
      }
   }
   return $tr;
}

# === transliterate a string ===
# The input string may contain any character.
# Transliterates only unicode hangul syllables (AC00-D7A3),
# returns other characters including hangul jamo (1100-11F9)
# and hangul compatibility jamo.
sub transliterate_line {
   my($str) = @_;
   my $tr;
   my(@char) = split(//,$str);
   foreach my $c (@char) {
      if (ord($c)>=0xAC00 && ord($c)<=0xD7A3){ 
         $tr = $tr . transliterate_chr($c);
      } else {
         $tr = $tr . $c;
      }
   }
   return $tr;
}

# === transliterate ===
# Transliterates word by word
sub transliterate {
   my $self = shift;

   #my($str) = @_;
   my $str = shift;
   my $tr;
   my(@word) = split /([^\x{AC00}-\x{D7A3}]+)/, $str;
   foreach my $w (@word) {
      if ($w =~ m/^[\x{AC00}-\x{D7A3}]+$/) {
         $tr = $tr . $self->transliterate_hangul_word($w);
      } else {
         $tr = $tr . $w;
      }
   }

   return $tr; 
}


#
# == HANGULIZE (REVERSE TRANSLITERATION) ==
#
# H: head, B: body, F: foot
#  H?BF?(HBF?)*

# === hangulize ===
# reverse transliteration : hangulizes a transliterated strings
# for example: hangulize('hangugmal') returns '한국말'
sub hangulize {
   my $self = shift;
   my $sep = $self->sep;

   my($str) = @_;
   my $h;

   if ($sep ne '') {
      my @word = split(/\Q$sep\E/, $str);
      foreach(@word) { $h = $h . $self->get_han($_); }
   } else {
      $h = $h . $self->get_han($str);
   }
   return $h;
}

#------------------------------
# hangulizes an array of alphabets into one hangul chr
# for example, hangulize_code(('h', 'a', 'n')) returns '한'
sub hangulize_code {
   my $self = shift;

   my($head, $body, $foot) = @_;
   my @hancode = ($self->{HEADMAP}->{$head}, $self->{BODYMAP}->{$body}, $self->{FOOTMAP}->{$foot});
   return $self->compose(@hancode);
}


#-------------------------------
# lookup $str, @list_of_jamo_transliteration
# eg. lookup('ssan', @CONSONANT) returns ('ss', 'an')
#     where @CONSONANT has an item 'ss' 
sub lookup {
   my $self = shift;

   my($str, @where) = @_;
   my $found = $NotFound;
   my $rest = $str;
   foreach(@where) {
      if ($_ eq substr($str, 0, length($_))) {
         if ($found eq $NotFound) {
            $found = $_;
            $rest = substr($str, length($_));
         } elsif (length($found) < length($_)) {
            $found = $_;
            $rest = substr($str, length($_));
         }
      }
   }
#  if($found eq $NotFound) {
#     if(@where == @HEAD) {$found = $HEAD[11];}
#     elsif (@where == @BODY) {$found = $NotFound;}
#     elsif (@where == @FOOT) {$found = $FOOT[0];}
#     $rest = $str;
#  }
   return ($found, $rest);
}

#-------------------------------
#     $SEP = "/"; $NAUGHT = "'";
#     isse     = 이써
#     iss'e    = 있어      :     is/se     = 잇서
#     ibsi   =  입시
#     ibs'i  =  잆이 
#     ibsse    = 입써     :     ibs/se   = 잆서
#     ibssse  = 잆써

#-------------------------------
# get_head($str)
# eg. get_head("ssan") retunrs ("ss", "an")
sub get_head {
   my $self = shift;

   my($str) = @_;
   my($head, $rest) = $self->lookup($str, @{$self->head});
   return ($head, $rest);
}

#-------------------------------
# get_body($str) 
# eg. get_body("wan") returns ("wa", "n")
sub get_body {
   my $self = shift;

   my($str) = @_;
   my($body, $rest) = $self->lookup($str, @{$self->body});
   return ($body, $rest);
}
#-------------------------------
# get_foot($str) 
# eg. get_foot("bssan") returns ("bs", "san")
sub get_foot {
   my $self = shift;

   my($str) = @_;
   my($foot, $rest) = $self->lookup($str, @{$self->foot});
   return ($foot, $rest);
}

#-------------------------------
# look_ahead for the next head - body sequence
# case :
#  normal :    look_ahead("mal") == "m";
#  no_head: look_ahead("an") == "";
#  no_body: look_ahead("kkkkk") eq $NotFound;
sub look_ahead {
   my $self = shift;

   my ($right) = @_;
   my $head;
   my $body;
   ($head, $right) = $self->get_head($right);
   ($body, $right) = $self->get_body($right);

   if ($body eq $NotFound) { return $NotFound;}
   elsif($head eq $NotFound) {return "";}
   else { return $head;}
}

#-------------------------------
# get a hangul string from a transliteration :
# Makes the first hangul syllable from a transliterated string
# and recursively processes the rest.  
# for example: get_han('hangugmal') returns unicode string '한국말'
sub get_han {
   my $self = shift;
   my $NAUGHT = $self->naught;
   my $FILL = "";     # jongseong filler

   my ($right) = @_;
   my $head; 
   my $body;
   my $foot;
   my $look_ahead_token;
   my $h;


   show_process(0, "begin", $h, $head, $body, $foot, $look_ahead_token, $right);

   ($head, $right) = $self->get_head($right);
   show_process(1, "get_head", $h, $head, $body, $foot, $look_ahead_token, $right);
   
   ($body, $right) = $self->get_body($right);
   show_process(2, "get_body", $h, $head, $body, $foot, $look_ahead_token, $right);

   if ($head eq $NotFound && $body eq $NotFound ) {
      $h = $h . substr($right,0,1);
      show_process(21, "no head", $h, $head, $body, $foot, $look_ahead_token, $right);
      if($right ne "") {$h = $h . $self->get_han(substr($right,1));}
   } elsif ($head ne $NotFound && $body eq $NotFound) {
      $h = $h . $head;
      show_process(22, "no body", $h, $head, $body, $foot, $look_ahead_token, $right);
      if($right ne "") {$h = $h . substr($right, 0, 1) . $self->get_han(substr($right,1));}
   } else {
      if($head eq $NotFound) { $head = $NAUGHT; }
      ($foot, $right) = $self->get_foot($right);
      show_process(3, "get_foot", $h, $head, $body, $foot, $look_ahead_token, $right);
      if ($foot eq $NotFound || $foot eq $FILL) {
         $h = $h . $self->hangulize_code($head, $body, $FILL);
         show_process(31, "no foot", $h, $head, $body, $foot, $look_ahead_token, $right);
         if($right ne "") {$h = $h . $self->get_han($right);}
      } elsif($right eq "") {
         $h = $h . $self->hangulize_code($head, $body, $foot);
         show_process(32, "eof", $h, $head, $body, $foot, $look_ahead_token, $right);
      } else {
         $look_ahead_token = $self->look_ahead($right);
         show_process(4, "look_ahead", $h, $head, $body, $foot, $look_ahead_token, $right);
         if ($look_ahead_token eq $NotFound || $look_ahead_token eq $NAUGHT) {
            $h = $h . $self->hangulize_code($head, $body, $foot);
            show_process(41, "no look", $h, $head, $body, $foot, $look_ahead_token, $right);
            if($right ne "") {$h = $h . $self->get_han($right);}
         }  else {
            ($foot, $right) = $self->get_correct_foot($foot, $look_ahead_token, $right);
            $h = $h . $self->hangulize_code($head, $body, $foot);
            show_process(42, "get_correct_foot", $h, $head, $body, $foot, $look_ahead_token, $right);
            if($right ne "") {$h = $h . $self->get_han($right);}
         }

      }
   }
   return $h;
}



$, = "\t";
sub show_process {
   if(0) {
      my($id, $desc, $h, $head, $body, $foot, $look_ahead_token, $right) = @_;
      print $id , $desc, $h, $head, $body, $foot, $look_ahead_token, $right, "\n";
   }
}

#-------------------------------
# correct foot
# <n:a:nh>($NAUGHT)a  -->    <n:a:n>ha
# <n:a:bs>(s)sa              -->    <n:a:b>ssa
# <n:a:nh>(t)ta               -->    <n:a:nh>ta
#my $foot_p, my $look_ahead_token, my $right_p;
#my $foot, my $right;
sub get_correct_foot {
   my $self = shift;

   my ($foot_p, $look_ahead_token, $right_p) = @_;
   my $foot, my $right;
   $foot_p = $foot_p . $look_ahead_token;;
   $right_p = substr($right_p, length($look_ahead_token));
   $foot = $foot_p;
   $right = $right_p;
   my $found = $NotFound;
   
   foreach(@{$self->head}) {
      if ($_ eq substr($foot_p, length($foot_p) - length($_))) {
         if ($found eq $NotFound) {
            $found = $_;
            $foot = substr($foot_p, 0, length($foot)-length($found));
            $right = $found . $right_p;
         } elsif (length($found) < length($_)) {
            $found = $_;
            $foot = substr($foot_p, 0, length($foot_p)-length($found));
            $right = $found . $right_p;
         }
      }
   }

   return ($foot, $right);
}

1;
__END__
=encoding utf8

=head1 NAME

Encode::Korean - Perl extension for Encoding of Korean: Transliterator Generator 

=head1 SYNOPSIS

  use Encode::Korean::TransliteratorGenerator;

  my $coder = Encode::Korean::TransliteratorGenerator->new();

  $coder->consonants(@CONSONANTS);
  $coder->vowels(@VOWELS);
  $coder->sep($SEP);
  $coder->make();

  while($utf_input = <>) {
	print $coder->encode(decode 'utf8', $utf_input);
  }

=head1 DESCRIPTION

This module provide a generic Korean transliterator class. You can define your
own rules and create your own transliterator object. 

The transliteration based encoding modules uses this class.
See L<Encode::Korean>.



=head2 How to define a custom transliteration set

 @CONSONANT  : array of 19 consonant letters
 @VOWEL      : array of 21 vowel letters
 $EL         : jongseong l
 $ELL        : consecutive l's 
 $NAUGHT     : soundless choseong ieung
 $SEP        : syllable separator
 $MODE       : CamelCase, greedy_sep, smart_sep 
 

eg. South Korean Standard

 @CONSONANT = qw(g kk n d tt r m b pp s ss ng j jj ch k t p h);
 @VOWEL = qw(a ae ya yae eo e yeo ye o wa wae oe yo u wo we wi yu eu ui i);
 $EL = "l";
 $ELL = "ll";
 $NAUGHT = "'";
 $SEP = "-";

=head2 TRANSLITERATION MODES

Transliteration modes for ambiguous syllable boundary resolution. 


=head3 1. Use CamelCase

Makes syllables capitalized. Ignores $NAUGHT and $SEP. Not yet implemented at all.

 eg. 하나 -> HaNa, 한아 -> HanA

=head3 2. Greedy Separator

Insert $SEP between syllables. Implemented. The object can produces (when encode)
transliteration with greedy separator mode and recognize (decode) it.

 eg. 하나 -> ha.na, 한아 -> han'a, where $SEP = '.'; $NAUGHT = "'";
 eg. 하나 -> ha.na, 한아 -> han.a, where $SEP = '.'; $NAUGHT = undef;

=head3 3. Smart Separator

Insert $SEP when syllable boundaries are ambiguous in transliteration.
Partially implemented. The object can recognize (decode) it but does not
produce it.

 If $NAUGHT is defined and is not null:

   insert $NAUGHT for the soundless head (choseong ieung)
   insert $SEP between consonant groups.

   eg. 하나 -> hana, 한아 -> han'a
   eg. 앉자 -> anc.ca, 안짜 -> an.cca

 else :

   insert $SEP for the soundless head and between consonant groups.

   eg. 하나 -> hana,    한아 -> han.a
   eg. 앉자 -> anc.ca,  안짜 -> an.cca 
       앉하 -> anc.ha,  안차 -> an.cha
   eg. 갂아 -> kakk.a,  각가 -> kak.ka, 가까 -> kakka
       각까 -> kak.kka, 갂가 -> kakk.ka
       갂까 -> kakk.kka

=head1 SEE ALSO


=head1 AUTHOR

You Hyun Jo, E<lt>you at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by You Hyun Jo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
# vim: set ts=3 sts=3 sw=3 et:
