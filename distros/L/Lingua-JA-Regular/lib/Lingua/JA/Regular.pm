package Lingua::JA::Regular;

use strict;
use vars qw($VERSION);
$VERSION = '0.09';

use 5.005;
use Jcode;

use Lingua::JA::Regular::Table;

use vars qw(
    $HANKAKU_ASCII
    $ZENKAKU_ASCII
    $KATAKANA
    $HIRAGANA
    $CHARACTER_STRICT_REGEX
    $CHARACTER_UNDEF_REGEX

    %KANJI_ALT_TABLE
    %WIN_ALT_TABLE
    %MAC_ALT_TABLE
);

use overload '""' => \&to_s;

sub new {
    my $class = shift;
    my $str   = shift;
    my $icode = shift || getcode($str);

    if (defined $icode and $icode =~ /^(:?jis|sjis|utf8)$/) {
        return bless {
            str   => Jcode->new($str, $icode)->euc,
            icode => $icode
        }, $class;
    }
    else {
        return bless {str => $str}, $class;
    }
}

sub to_s {
    my $self = shift;

    if (defined $self->{icode}) {
        my $icode = $self->{icode};
        $self->{str} = Jcode->new($self->{str}, 'euc')->$icode();
    }

    return $self->{str};
}

sub linefeed {
    my $self = shift;
    my $lf   = shift;

    $lf = "\n" unless(defined $lf);

    $self->{str} =~ s/\r\n|\r|\n/$lf/g;

    return $self;
}

sub strip {
    my $self = shift;

    $self->{str} =~ s/^\s+//;
    $self->{str} =~ s/\s+$//;

    return $self;
}

sub uc {
    my $self = shift;
    $self->{str} = CORE::uc $self->{str};
    return $self;
}

sub lc {
    my $self = shift;
    $self->{str} = CORE::lc $self->{str};
    return $self;

}

sub z_ascii {
    my $self = shift;
    my $str = Jcode->new($self->{str}, 'euc');

    $str->tr('-', "\xA1\xDD");
    $str->tr($HANKAKU_ASCII, $ZENKAKU_ASCII);

    $self->{str} = $str->euc;
    return $self;
}

sub h_ascii {
    my $self = shift;
    my $str = Jcode->new($self->{str}, 'euc');

    $str->tr("\xA1\xDD", '-');
    $str->tr($ZENKAKU_ASCII, $HANKAKU_ASCII);

    $self->{str} = $str->euc;
    return $self;
}

sub z_kana {
    my $self = shift;
    my $str = Jcode->new($self->{str}, 'euc');

    $str->h2z;

    $self->{str} = $str->euc;
    return $self;
}

sub h_kana {
    my $self = shift;
    my $str = Jcode->new($self->{str}, 'euc');

    $str->z2h;

    $self->{str} = $str->euc;
    return $self;
}

sub z_space {
    my $self = shift;
    my $str = Jcode->new($self->{str}, 'euc');

    $str->tr(' ', "\xA1\xA1");

    $self->{str} = $str->euc;
    return $self;
}

sub h_space {
    my $self = shift;

    my $str = Jcode->new($self->{str}, 'euc');
    $str->tr("\xA1\xA1", ' ');

    $self->{str} = $str->euc;
    return $self;
}

sub z_strip {
    my $self = shift;

    $self->{str} =~ s/^(?:\xA1\xA1|\s)+//;
    $self->{str} =~ s/(?:\xA1\xA1|\s)+$//;

    return $self;
}

sub hiragana {
    my $self = shift;
    my $str = Jcode->new($self->{str}, 'euc');

    $str->tr($KATAKANA, $HIRAGANA);

    $self->{str} = $str->euc;
    return $self;
}

sub katakana {
    my $self = shift;

    my $str = Jcode->new($self->{str}, 'euc');
    $str->tr($HIRAGANA, $KATAKANA);

    $self->{str} = $str->euc;
    return $self;
}

sub kanji {
    my $self = shift;

    require Lingua::JA::Regular::Table::Kanji;
    import  Lingua::JA::Regular::Table::Kanji;

    $self->{str} =~ s{($CHARACTER_UNDEF_REGEX)}{
        defined($KANJI_ALT_TABLE{$1})? $KANJI_ALT_TABLE{$1} : $1
    }ogex;

    return $self;
}

sub win {
    my $self = shift;

    require Lingua::JA::Regular::Table::Windows;
    import  Lingua::JA::Regular::Table::Windows;

    $self->{str} =~ s{($CHARACTER_UNDEF_REGEX)}{
        defined($WIN_ALT_TABLE{$1})? $WIN_ALT_TABLE{$1} : $1
    }ogex;

    return $self;
}

sub mac {
    my $self = shift;

    require Lingua::JA::Regular::Table::Macintosh;
    import  Lingua::JA::Regular::Table::Macintosh;

    $self->{str} =~ s{($CHARACTER_UNDEF_REGEX)}{
        defined($MAC_ALT_TABLE{$1})? $MAC_ALT_TABLE{$1} : $1
    }ogex;

    return $self;
}

sub geta {
    my $self = shift;

    #
    # EUC-JP undef character to GETA
    #
    $self->{str} =~ s/$CHARACTER_UNDEF_REGEX/\xA2\xAE/go;

    #
    # measures of binary code
    # - delete EUC-JP character
    # - binary to GETA
    #
    my $tmp = $self->{str};
    $tmp =~ s/$CHARACTER_STRICT_REGEX/ /go;
    $tmp =~ s/^\s+//;
    $tmp =~ s/\s+$//;

    for my $undef (split /\s+/, $tmp) {
        $self->{str} =~
            s/
                (?<!\x8F)
                $undef
                (?=(?:[\xA1-\xFE][\xA1-\xFE])*(?:[\x00-\x7F\x8E\x8F]|\z))
            /\xA2\xAE/x;
    }

    return $self;
}


sub regular {
    my $self = shift;


    if (defined $ENV{HTTP_USER_AGENT}) {
        if ($ENV{HTTP_USER_AGENT} =~ /Windows/) {
            $self->win;
        }
        elsif ($ENV{HTTP_USER_AGENT} =~ /Mac/) {
            $self->mac;
        }
    }

    $self->strip->linefeed->z_kana->h_ascii->kanji;

    return $self->geta->to_s;
}

1;

__END__

=head1 NAME

Lingua::JA::Regular - Regularize of the Japanese character.


=head1 SYNOPSIS

  my $string = Lingua::JA::Regular->new($string)->regular;


  my $regular = Lingua::JA::Regular->new($string);

  $regular->strip->linefeed->h_ascii->z_kana;

  if ($ENV{HTTP_USER_AGENT} =~ /Windows/) {
      $regular->win;
  }
  elsif ($ENV{HTTP_USER_AGENT} =~ /Mac/) {
      $regular->mac;
  }

  print $regular->geta->to_s;

=head1 DESCRIPTION

Regularize of the Japanese character

Converts platform specific charactes to standard characters.

Converts multi byte(Japanese) alphanumeric and symbolcharacters to
single byte characters.


=head1 METHODS

=over 4

=item new

  my $str = Convert::Character->new($str);

Create object.

=item to_s

  $str->to_s;

It changes into a character sequence from an object.

=item linefeed

  $str->linefeed;

  $str->linefeed("\r");

  $str->linefeed("\r\n");

  $str->linefeed("<br>");

A new-line character(\r\n, \n, \r) is replaced by the argument.
If an argument becomes undef, it will replace by "\n".

=item strip

  $str->strip;

The blank character of order is deleted.

=item uc

  $str->uc;

uppercase.

=item lc

  $str->lc;

lowercase.

=item z_ascii

alphabet, number, and sign are changed into ZENKAKU.

=item h_ascii

alphabet, number, and sign are changed into HANKAKU.

=item z_kana

h2z of Jcode is performed.

=item h_kana

z2h of Jcode is performed.

=item z_space

HANKAKU space is changed into a ZENKAKU space.

=item h_space

ZENKAKU space is changed into a HANKAKU space.

=item z_strip

The blank and ZENKAKU space character of order is deleted.

=item hiragana

It changes into a HIRAGANA.

=item katakana

It changes into a KATAKANA.

=item kanji

The model dependence character of KANJI is changed
into an alternative character.

=item win

The model dependence character of Windows is changed
into an alternative character.

=item mac

The model dependence character of Macintosh is changed
into an alternative character.

=item geta

The model dependence character is changed into an GETA.

=item regular

It is the same as the result which performed strip,
(win|mac), linefeed, z_kana, h_ascii, kanji, ,geta, and the to_s method.

=back

=head1 AUTHOR

KIMURA, takefumi E<lt>takefumi@takefumi.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Jcode>,
L<Lingua::JA::Regular::Table>,
L<Lingua::JA::Regular::Table::Kanji>,
L<Lingua::JA::Regular::Table::Macintosh>,
L<Lingua::JA::Regular::Table::Windows>

L<http://code.mfac.jp/trac/browser/CPAN/takefumi/Lingua-JA-Regular/>

=cut
