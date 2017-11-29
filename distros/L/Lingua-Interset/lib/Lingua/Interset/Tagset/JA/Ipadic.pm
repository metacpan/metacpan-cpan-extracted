# ABSTRACT: Driver for the IPADIC tagset.

package Lingua::Interset::Tagset::JA::Ipadic;
use strict;
use warnings;
our $VERSION = '3.010';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset';



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'ja::ipadic';
}


### TODO: find a better way to distinguish bound-verbs (動詞-非自立) and auxiliary verbs (助動詞)

# We decided not to divide tags into subcategories (by default they should
# be divided by '-')
my %postable =
(

    # tag translations taken from http://sourceforge.jp/projects/ipadic/docs/postag.txt/ja/1/postag.txt.txt

    '名詞'              => ['pos' => 'noun'], # noun
    '名詞-一般'         => ['pos' => 'noun', 'nountype' => 'com'], # noun-common
    '名詞-固有名詞'     => ['pos' => 'noun', 'nountype' => 'prop'], # noun-proper
    '名詞-固有名詞-一般'    => ['pos' => 'noun', 'nountype' => 'prop', 'other' => 'misc'], # noun-proper-misc
    '名詞-固有名詞-人名'    => ['pos' => 'noun', 'nountype' => 'prop', 'nametype' => 'prs'], # noun-proper-person
    '名詞-固有名詞-人名-一般'   => ['pos' => 'noun', 'nountype' => 'prop', 'nametype' => 'prs', 'other' => 'misc'], # noun-proper-person-misc
    '名詞-固有名詞-人名-姓' => ['pos' => 'noun', 'nountype' => 'prop', 'nametype' => 'sur'], # noun-proper-person-surname
    '名詞-固有名詞-人名-名' => ['pos' => 'noun', 'nountype' => 'prop', 'nametype' => 'giv'], # noun-proper-person-given_name
    '名詞-固有名詞-組織'    => ['pos' => 'noun', 'nountype' => 'prop', 'nametype' => 'com'], # noun-proper-organization
    '名詞-固有名詞-地域'    => ['pos' => 'noun', 'nountype' => 'prop', 'nametype' => 'geo'], # noun-proper-place
    '名詞-固有名詞-地域-一般'   => ['pos' => 'noun', 'nountype' => 'prop', 'nametype' => 'geo', 'other' => 'misc'], # noun-proper-place-misc
    '名詞-固有名詞-地域-国' => ['pos' => 'noun', 'nountype' => 'prop', 'nametype' => 'geo', 'other' => 'country'], # noun-proper-place-country
    '名詞-代名詞'       => ['pos' => 'noun', 'prontype' => 'prn'], # noun-pronoun
    '名詞-代名詞-一般'  => ['pos' => 'noun', 'prontype' => 'prn', 'other' => 'misc'], # noun-pronoun-misc
    '名詞-代名詞-縮約'  => ['pos' => 'noun', 'prontype' => 'prn', 'other' => 'postpron'], # noun-pronoun-contraction ?? 'adpostype' => 'postpron' ??
    '名詞-副詞可能'     => ['pos' => 'noun', 'other' => 'adv'], # noun-adverbial
    '名詞-サ変接続'     => ['pos' => 'noun', 'other' => 'verb'], # noun-verbal
    '名詞-形容動詞語幹' => ['pos' => 'noun', 'other' => 'adj'], # noun-adjective
    '名詞-数'           => ['pos' => 'num'], # noun-numeral
    '名詞-非自立'       => ['pos' => 'noun', 'other' => 'affix'], # noun-affix
    '名詞-非自立-一般'  => ['pos' => 'noun', 'other' => 'affix-misc'], # noun-affix-misc
    '名詞-非自立-副詞可能'  => ['pos' => 'noun', 'other' => 'affix-adv'], # noun-affix-adverbial
    '名詞-非自立-助動詞語幹'    => ['pos' => 'noun', 'other' => 'affix-aux'], # noun-affix-aux
    '名詞-非自立-形容動詞語幹'  => ['pos' => 'noun', 'other' => 'affix-adj'], # noun-affix-adjective
    '名詞-特殊'         => ['pos' => 'noun', 'other' => 'special'], # noun-special
    '名詞-特殊-助動詞語幹'  => ['pos' => 'noun', 'other' => 'special-aux'], # noun-special-aux
    '名詞-接尾'         => ['pos' => 'noun', 'other' => 'suffix'], # noun-suffix
    '名詞-接尾-一般'    => ['pos' => 'noun', 'other' => 'suffix-misc'], # noun-suffix-misc
    '名詞-接尾-人名'    => ['pos' => 'noun', 'other' => 'suffix-prs'], # noun-suffix-person
    '名詞-接尾-地域'    => ['pos' => 'noun', 'other' => 'suffix-place'], # noun-suffix-place
    '名詞-接尾-サ変接続'    => ['pos' => 'noun', 'other' => 'suffix-verb'], # noun-suffix-verbal
    '名詞-接尾-助動詞語幹'  => ['pos' => 'noun', 'other' => 'suffix-aux'], # noun-suffix-aux
    '名詞-接尾-形容動詞語幹'    => ['pos' => 'noun', 'other' => 'suffix-adj'], # noun-suffix-adjective
    '名詞-接尾-副詞可能'    => ['pos' => 'noun', 'other' => 'suffix-adv'], # noun-suffix-adverbal
    '名詞-接尾-助数詞'  => ['pos' => 'noun', 'nountype' => 'class'], # noun-suffix-classifier
    '名詞-接尾-特殊'    => ['pos' => 'noun', 'other' => 'suffix-special'], # noun-suffix-special
    '名詞-接続詞的'     => ['pos' => 'noun', 'other' => 'suffix-conj'], # noun-suffix-conjunctive
    '名詞-動詞非自立的' => ['pos' => 'noun', 'other' => 'suffix-verb_aux'], # noun-verbal_aux
    '名詞-引用文字列'   => ['pos' => 'noun', 'other' => 'quote'], # noun-quote
    '名詞-ナイ形容詞語幹'   => ['pos' => 'noun', 'other' => 'nai_adj'], # noun-nai_adjective
    '接頭詞'            => ['other' => 'prefix'], # prefix
    '接頭詞-名詞接続'   => ['pos' => 'noun', 'other' => 'prefix'], # prefix-nominal
    '接頭詞-動詞接続'   => ['pos' => 'verb', 'other' => 'prefix'], # prefix-verbal
    '接頭詞-形容詞接続' => ['pos' => 'adj', 'other' => 'prefix'], # prefix-adjectival
    '接頭詞-数接続'     => ['pos' => 'num', 'other' => 'prefix'], # prefix-numerical
    '動詞'              => ['pos' => 'verb'], # verb
    '動詞-自立'         => ['pos' => 'verb', 'other' => 'main'], # verb-main (independent)
    '動詞-非自立'       => ['pos' => 'verb', 'verbtype' => 'aux', 'other' => 'bound'], # verb-aux (non-independent)
    '動詞-接尾'         => ['pos' => 'verb', 'other' => 'suffix'], # verb-suffix
    '形容詞'            => ['pos' => 'adj'], # adjective
    '形容詞-自立'       => ['pos' => 'adj', 'other' => 'main'], # adjective-main (independent)
    '形容詞-非自立'     => ['pos' => 'adj', 'verbtype' => 'aux', 'other' => 'bound'], # adjective-aux (non-independent)
    '形容詞-接尾'       => ['pos' => 'adj', 'other' => 'suffix'], # adjective-suffix
    '副詞'              => ['pos' => 'adv'], # adverb
    '副詞-一般'         => ['pos' => 'adv', 'other' => 'misc'], # adverb-misc
    '副詞-助詞類接続'   => ['pos' => 'adv', 'other' => 'conj'], # adverb-particle_conjunction
    '連体詞'            => ['pos' => 'adj', 'morphpos' => 'noun'], # adnominal
    #'連体詞'            => ['pos' => 'adj', 'other' => 'adnominal'], # adnominal
    '接続詞'            => ['pos' => 'conj'], # conjunction
    '助詞'              => ['pos' => 'adp', 'adpostype' => 'post'], # particle
    '助詞-格助詞'       => ['pos' => 'adp', 'adpostype' => 'post', 'other' => 'case'], # particle-case
    '助詞-格助詞-一般'  => ['pos' => 'adp', 'adpostype' => 'post', 'other' => 'case-misc'], # particle-case-misc
    '助詞-格助詞-引用'  => ['pos' => 'adp', 'adpostype' => 'post', 'other' => 'quote'], # particle-case-quote
    '助詞-格助詞-連語'  => ['pos' => 'adp', 'adpostype' => 'post', 'other' => 'compound'], # particle-compound
    '助詞-接続助詞'     => ['pos' => 'adp', 'adpostype' => 'post', 'other' => 'conj'], # particle-conjunctive
    '助詞-係助詞'       => ['pos' => 'adp', 'adpostype' => 'post', 'other' => 'dependency'], # particle-dependency
    '助詞-副助詞'       => ['pos' => 'adp', 'adpostype' => 'post', 'other' => 'adv'], # particle-adverbial
    '助詞-間投助詞'     => ['pos' => 'adp', 'adpostype' => 'post', 'other' => 'int'], # particle-interjective
    '助詞-並立助詞'     => ['pos' => 'conj', 'adpostype' => 'post', 'conjtype' => 'coor'], # particle-coordinate
    '助詞-終助詞'       => ['pos' => 'adp', 'adpostype' => 'post', 'other' => 'final'], # particle-final
    '助詞-副助詞／並立助詞／終助詞' => ['pos' => 'adp', 'adpostype' => 'post', 'other' => 'adv/conj/final'], # particle-adverbial/conjunctive/final
    '助詞-連体化'       => ['pos' => 'adp', 'adpostype' => 'post', 'case' => 'gen'], # particle-adnominalizer
    '助詞-副詞化'       => ['pos' => 'adp', 'adpostype' => 'post', 'other' => 'adverbializer'], # particle-adverbializer
    '助詞-特殊'         => ['pos' => 'adp', 'adpostype' => 'post', 'other' => 'special'], # particle-special
    '助動詞'            => ['pos' => 'verb', 'verbtype' => 'aux'], # aux
    '感動詞'            => ['pos' => 'int'], # exclamation
    '記号'              => ['pos' => 'sym'], # symbol
    '記号-一般'         => ['pos' => 'sym', 'other' => 'misc'], # symbol-misc
    '記号-句点'         => ['pos' => 'punc', 'punctype' => 'peri'], # symbol-comma
    '記号-読点'         => ['pos' => 'punc', 'punctype' => 'comm'], # symbol-period
    '記号-空白'         => ['pos' => 'punc', 'other' => 'space'], # symbol-space
    '記号-アルファベット'   => ['pos' => 'sym', 'other' => 'alphabet'], # symbol-alphabetic
    '記号-括弧開'       => ['pos' => 'punc', 'punctype' => 'brck', 'puncside' => 'ini'], # symbol-left_parenthesis
    '記号-括弧閉'       => ['pos' => 'punc', 'punctype' => 'brck', 'puncside' => 'fin'], # symbol-right_parenthesis
    'その他'            => ['other' => 'other'], # other
    'その他-間投'       => ['pos' => 'int', 'other' => 'other'], # other-interjection
    'フィラー'          => ['other' => 'filler'], # filler
    '非言語音'          => ['other' => 'sound'], # nonlinguistic_sound
    '語断片'            => ['other' => 'fragment'], # fragment
);



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;

    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset('ja::ipadic');

    $tag =~ s/\n//;   # user should be taking care of this
    my $assignments = $postable{$tag};
    $fs->add(@{$assignments}) if $assignments;

    return $fs;
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $tag = '';

    my $pos = $fs->pos();

    # Prefixes
    if ($fs->other() eq 'prefix')
    {
      if ($pos)
      {
        # prefix-nominal
        if ($pos eq 'noun')
        {
          $tag = '接頭詞-名詞接続';
        }
        # prefix-vebal
        elsif ($pos eq 'verb')
        {
          $tag = '接頭詞-動詞接続';
        }
        # prefix-adjectival
        elsif ($pos eq 'adj')
        {
          $tag = '接頭詞-形容詞接続';
        }
        # prefix-numeral
        elsif ($pos eq 'num')
        {
          $tag = '接頭詞-数接続';
        }
      }
      # prefix
      else
      {
        $tag = '接頭詞';
      }
    }

    # Nouns
    elsif ($pos eq 'noun')
    {
      if ($fs->nountype())
      {
        # noun-common
        if ($fs->nountype() eq 'com')
        {
          $tag = '名詞-一般';
        }
        # noun-suffix-classifier
        elsif ($fs->nountype() eq 'class')
        {
          $tag = '名詞-接尾-助数詞';
        }

        # Proper nouns
        else
        {
          # noun-proper-person-misc noun-proper-person
          if ($fs->nametype() eq 'prs')
          {
            if ($fs->other() eq 'misc')
            {
              $tag = '名詞-固有名詞-人名-一般';
            }
            else
            {
              $tag = '名詞-固有名詞-人名';
            }
          }
          # noun-proper-person-surname
          elsif ($fs->nametype() eq 'sur')
          {
            $tag = '名詞-固有名詞-人名-姓';
          }
          # noun-proper-person-given_name
          elsif ($fs->nametype() eq 'giv')
          {
            $tag = '名詞-固有名詞-人名-名';
          }
          # noun-proper-organization
          elsif ($fs->nametype() eq 'com')
          {
            $tag = '名詞-固有名詞-組織';
          }
          # noun-proper-place-misc noun-proper-place-country noun-proper-place
          elsif ($fs->nametype() eq 'geo')
          {
            if ($fs->other() eq 'country')
            {
              $tag = '名詞-固有名詞-地域-国';
            }
            elsif ($fs->other() eq 'misc')
            {
              $tag = '名詞-固有名詞-地域-一般';
            }
            else
            {
              $tag = '名詞-固有名詞-地域';
            }
          }
          # noun-proper-misc
          elsif ($fs->other() eq 'misc')
          {
            $tag = '名詞-固有名詞-一般';
          }
          # noun-proper
          else
          {
            $tag = '名詞-固有名詞';
          }
        }
      }

      # noun-pronoun-contraction noun-pronoun-misc noun-pronoun
      elsif ($fs->prontype())
      {
        if ($fs->other eq 'postpron')
        {
          $tag = '名詞-代名詞-縮約';
        }
        elsif ($fs->other() eq 'misc')
        {
          $tag = '名詞-代名詞-一般';
        }
        else
        {
          $tag = '名詞-代名詞';
        }
      }

      # noun-adverbial
      elsif ($fs->other() eq 'adv')
      {
        $tag = '名詞-副詞可能';
      }

      # noun-verbal
      elsif ($fs->other() eq 'verb')
      {
        $tag = '名詞-サ変接続';
      }

      # noun-adjective
      elsif ($fs->other() eq 'adj')
      {
        $tag = '名詞-形容動詞語幹';
      }

      # Affixes
      elsif ($fs->other() =~ /affix/)
      {
        # noun-affix-adverbial
        if ($fs->other() =~ /-adv$/)
        {
          $tag = '名詞-非自立-副詞可能';
        }
        # noun-affix-aux
        elsif ($fs->other() =~ /-aux$/)
        {
          $tag = '名詞-非自立-助動詞語幹';
        }
        # noun-affix-adjective
        elsif ($fs->other() =~ /-adj$/)
        {
          $tag = '名詞-非自立-形容動詞語幹';
        }
        # noun-affix-misc
        elsif ($fs->other() =~ /-misc$/)
        {
          $tag = '名詞-非自立-一般';
        }
        # noun-affix
        else
        {
          $tag = '名詞-非自立';
        }
      }

      # Suffixes
      elsif ($fs->other() =~ /suffix/)
      {
        # noun-suffix-person
        if ($fs->other() =~ /-prs$/)
        {
          $tag = '名詞-接尾-人名';
        }
        # noun-suffix-place
        elsif ($fs->other() =~ /-place$/)
        {
          $tag = '名詞-接尾-地域';
        }
        # noun-suffix-verbal
        elsif ($fs->other() =~ /-verb$/)
        {
          $tag = '名詞-接尾-サ変接続';
        }
        # noun-suffix-aux
        elsif ($fs->other() =~ /-aux$/)
        {
          $tag = '名詞-接尾-助動詞語幹';
        }
        # noun-suffix-adjective
        elsif ($fs->other() =~ /-adj$/)
        {
          $tag = '名詞-接尾-形容動詞語幹';
        }
        # noun-suffix-adverbal
        elsif ($fs->other() =~ /-adv$/)
        {
          $tag = '名詞-接尾-副詞可能';
        }
        # noun-suffix-special
        elsif ($fs->other() =~ /-special$/)
        {
          $tag = '名詞-接尾-特殊';
        }
        # noun-suffix-conjunctive
        elsif ($fs->other() =~ /-conj$/)
        {
          $tag = '名詞-接続詞的';
        }
        # noun-suffix-verbal_aux
        elsif ($fs->other() =~ /-verb_aux$/)
        {
          $tag = '名詞-動詞非自立的';
        }
        # noun-suffix-misc
        elsif ($fs->other() =~ /-misc$/)
        {
          $tag = '名詞-接尾-一般';
        }
        # noun-suffix
        else
        {
          $tag = '名詞-接尾';
        }
      }

      # noun-suffix-classifier
      elsif ($fs->nountype() eq 'class')
      {
        $tag = '名詞-接尾-助数詞';
      }

      # noun-special
      elsif ($fs->other() eq 'special')
      {
        $tag = '名詞-特殊';
      }

      # noun-special-aux
      elsif ($fs->other() eq 'special-aux')
      {
        $tag = '名詞-特殊-助動詞語幹';
      }

      # noun-quote
      elsif ($fs->other() eq 'quote')
      {
        $tag = '名詞-引用文字列';
      }

      # noun-nai_adjective
      elsif ($fs->other() eq 'nai_adj')
      {
        $tag = '名詞-ナイ形容詞語幹';
      }

      # noun
      else
      {
        $tag = '名詞';
      }
    }

    # noun-numeral
    elsif ($pos eq 'num')
    {
      $tag = '名詞-数';
    }

    # Verbs
    elsif ($pos eq 'verb')
    {
      # verb-aux
      if ($fs->verbtype() eq 'aux' && $fs->other() eq 'bound')
      {
        $tag = '動詞-非自立';
      }
      # verb-suffix
      elsif ($fs->other() eq 'suffix')
      {
        $tag = '動詞-接尾';
      }
      # aux
      elsif ($fs->verbtype() eq 'aux')
      {
        $tag = '助動詞';
      }
      # verb-main
      elsif ($fs->other() eq 'main')
      {
        $tag = '動詞-自立';
      }
      # verb
      else
      {
        $tag = '動詞';
      }
    }

    # Adjectives
    elsif ($pos eq 'adj')
    {
      # adjective-aux
      if ($fs->verbtype() eq 'aux')
      {
        $tag = '形容詞-非自立';
      }
      # adjective-suffix
      elsif ($fs->other() eq 'suffix')
      {
        $tag = '形容詞-接尾';
      }
      # adjective-adnominal
      elsif ($fs->morphpos() eq 'noun')
      #elsif ($fs->other() eq 'adnominal')
      {
        $tag = '連体詞';
      }
      # adjective-main
      elsif ($fs->other() eq 'main')
      {
        $tag = '形容詞-自立';
      }
      # adjective
      else
      {
        $tag = '形容詞';
      }
    }

    # Adverbs
    elsif ($pos eq 'adv')
    {
      # adverb-particle_conjunction
      if ($fs->other() eq 'conj')
      {
        $tag = '副詞-助詞類接続';
      }
      # adverb-misc
      elsif ($fs->other() eq 'misc')
      {
        $tag = '副詞-一般';
      }
      # adverb
      else
      {
        $tag = '副詞';
      }
    }

    # particle-coordinate conjunction
    elsif ($pos eq 'conj')
    {
      if ($fs->adpostype())
      {
        $tag = '助詞-並立助詞';
      }
      else
      {
        $tag = '接続詞';
      }
    }

    # Particles (postpositions)
    elsif ($pos eq 'adp' && $fs->adpostype() eq 'post')
    {
      # particle-case-misc particle-case
      if ($fs->other() =~ /case/)
      {
        if ($fs->other() =~ /misc/)
        {
          $tag = '助詞-格助詞-一般';
        }
        else
        {
          $tag = '助詞-格助詞';
        }
      }
      # particle-case-quote
      elsif ($fs->other() eq 'quote')
      {
        $tag = '助詞-格助詞-引用';
      }
      # particle-compound
      elsif ($fs->other() eq 'compound')
      {
        $tag = '助詞-格助詞-連語';
      }
      # particle-conjunctive
      elsif ($fs->other() eq 'conj')
      {
        $tag = '助詞-接続助詞';
      }
      # particle-dependency
      elsif ($fs->other() eq 'dependency')
      {
        $tag = '助詞-係助詞';
      }
      # particle-adverbial
      elsif ($fs->other() eq 'adv')
      {
        $tag = '助詞-副助詞';
      }
      # particle-interjective
      elsif ($fs->other() eq 'int')
      {
        $tag = '助詞-間投助詞';
      }
      # particle-final
      elsif ($fs->other() eq 'final')
      {
        $tag = '助詞-終助詞';
      }
      # particle-adverbial/conjunctive/final
      elsif ($fs->other() eq 'adv/conj/final')
      {
        $tag = '助詞-副助詞／並立助詞／終助詞';
      }
      # particle-adnominalizer
      elsif ($fs->case() eq 'gen')
      {
        $tag = '助詞-連体化';
      }
      # particle-adverbializer
      elsif ($fs->other() eq 'adverbializer')
      {
        $tag = '助詞-副詞化';
      }
      # particle-special
      elsif ($fs->other() eq 'special')
      {
        $tag = '助詞-特殊';
      }
      # particle
      else
      {
        $tag = '助詞';
      }
    }

    # Punctuation and symbols
    elsif ($pos eq 'sym')
    {
        if ($fs->other() eq 'alphabet')
        {
          $tag = '記号-アルファベット';
        }
        elsif ($fs->other() eq 'misc')
        {
          $tag = '記号-一般';
        }
        else
        {
          $tag = '記号';
        }
    }
    elsif ($pos eq 'punc')
    {
      # symbol-left_parenthesis symbol-right_parenthesis
      if ($fs->punctype() eq 'brck')
      {
        if ($fs->puncside() eq 'ini')
        {
          $tag = '記号-括弧開';
        }
        else
        {
          $tag = '記号-括弧閉' ;
        }
      }
      # symbol-comma
      elsif ($fs->punctype() eq 'peri')
      {
        $tag = '記号-句点';
      }
      # symbol-period
      elsif ($fs->punctype() eq 'comm')
      {
        $tag = '記号-読点';
      }
      # symbol-space
      else
      {
        $tag = '記号-空白';
      }

    }

    # Special categories
    # filler
    elsif ($fs->other() eq 'filler')
    {
      $tag = 'フィラー';
    }
    # nonlinguistic_sound
    elsif ($fs->other() eq 'sound')
    {
      $tag = '非言語音';
    }
    # fragment
    elsif ($fs->other() eq 'fragment')
    {
      $tag = '語断片';
    }

    # Other
    else
    {
      # other-interjection other
      if ($fs->pos() eq 'int')
      {
        if ($fs->other() eq 'other')
        {
          $tag = 'その他-間投';
        }
        else
        {
          $tag = '感動詞';
        }
      }
      else
      {
        $tag = 'その他';
      }
    }

    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my @list = sort(keys(%postable));
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::JA::Ipadic - Driver for the IPADIC tagset.

=head1 VERSION

version 3.010

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::JA::Ipadic;
  my $driver = Lingua::Interset::Tagset::JA::Ipadic->new();
  my $fs = $driver->decode('名詞-代名詞');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('ja::ipadic', '名詞-代名詞');

=head1 DESCRIPTION

Interset driver for the IPADIC part-of-speech tagset.
Tag translations were taken from http://sourceforge.jp/projects/ipadic/docs/postag.txt/ja/1/postag.txt.txt

For more information about IPADIC tagset, see Yasuhiro Kawata - Towards a reference tagset for Japanese.

=head1 SEE ALSO

L<Lingua::Interset>
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dušan Variš <dvaris@seznam.cz>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
