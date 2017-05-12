package Lingua::EN::Alphabet::Deseret;

use 5.005;
use strict;
use warnings;
use utf8;
use Lingua::EN::Phoneme;
our $VERSION = 0.01;

our $lep = new Lingua::EN::Phoneme();

my $i=66600;
our %correspondence = map { $_ => chr($i++) } qw(

IY EY _a AO OW UW
IH EH AE AA AH UH

AY AW W  Y  HH
P  B  T  D  CH JH K  G
F  V  TH DH S  Z  SH ZH
R  L  M  N  NG

OY 
);

# fixups
$correspondence{'ER'} = chr(66600).chr(66633);

sub _transliterate_word_raw {
    my ($word) = @_;

    my @pronunciation = $lep->phoneme($word);

    return undef unless @pronunciation;

    my $result = '';

    for (@pronunciation) {
	s/[0-9]//g; # don't care about stress
	warn "CMU phoneset $_ does not appear in correspondence"
	    unless $correspondence{$_};
	$result .= $correspondence{$_};
    }
    
    $result =~ s/\x{10437}\x{1042D}/\x{1044F}/ig;

    if ($word =~ /^[A-Z][a-z]/) {
       # titlecase
       $result = ucfirst $result;
    } elsif ($word =~ /^[A-Z]/) {
       # uppercase
       $result = uc $result;
    }

    return $result;
}

sub _transliterate_word {
    my ($word) = @_;
    my $result = _transliterate_word_raw($word);
    return uc $word unless $result;
    return $result;
}

sub transliterate_raw {
    my ($sentence) = @_;

    $sentence =~ s/([A-Za-z]+)/_transliterate_word_raw($1)/eg;

    return $sentence;
}

sub transliterate {
    my ($sentence) = @_;

    $sentence =~ s/([A-Za-z]+)/_transliterate_word($1)/eg;

    return $sentence;
}

1;

=encoding utf-8
=head1 NAME

Lingua::EN::Alphabet::Deseret - transliterate the Latin to Deseret alphabets

=head1 AUTHOR

Thomas Thurman <tthurman@gnome.org>

=head1 SYNOPSIS

  use Lingua::EN::Alphabet::Deseret;

  print Lingua::EN::Alphabet::Deseret::transliterate("badger");
  # prints "𐐺𐐰𐐾𐐨𐑉"

=head1 DESCRIPTION

The Deseret alphabet was designed by the University of Deseret (now the
University of Utah) in the mid-1800s as a replacement for the Latin alphabet
for representing English.

Its ISO 15924 code is "Dsrt" 250.

This module transliterates English text from the Latin alphabet into the
Deseret alphabet.

𐐜𐐲 𐐔𐐯𐑅𐐨𐑉𐐯𐐻 𐐰𐑊𐑁𐐲𐐺𐐯𐐻 𐐶𐐱𐑆 𐐼𐐮𐑆𐐴𐑌𐐼 𐐺𐐴 𐑄𐐲 𐐧𐑌𐐲𐑂𐐨𐑉𐑅𐐲𐐻𐐨 𐐲𐑂 𐐔𐐯𐑅𐐨𐑉𐐯𐐻 (𐑌𐐵 𐑄𐐲
𐐧𐑌𐐲𐑂𐐨𐑉𐑅𐐲𐐻𐐨 𐐲𐑂 𐐧𐐻𐐫) 𐐮𐑌 𐑄𐐲 𐑋𐐮𐐼-1800𐐯𐑅 𐐰𐑆 𐐲 𐑉𐐮𐐹𐑊𐐩𐑅𐑋𐐲𐑌𐐻 𐑁𐐫𐑉 𐑄𐐲 𐐢𐐰𐐻𐐲𐑌 𐐰𐑊𐑁𐐲𐐺𐐯𐐻
𐑁𐐫𐑉 𐑉𐐯𐐹𐑉𐐮𐑆𐐯𐑌𐐻𐐮𐑍 𐐆𐑍𐑀𐑊𐐮𐑇.

𐐆𐐻𐑅 ISO 15924 𐐿𐐬𐐼 𐐮𐑆 "Dsrt" 250.

𐐜𐐮𐑅 𐑋𐐱𐐾𐐭𐑊 𐐻𐑉𐐰𐑌𐑅𐑊𐐮𐐻𐐨𐑉𐐩𐐻𐑅 𐐆𐑍𐑀𐑊𐐮𐑇 𐐻𐐯𐐿𐑅𐐻 𐑁𐑉𐐲𐑋 𐑄𐐲 𐐢𐐰𐐻𐐲𐑌 𐐰𐑊𐑁𐐲𐐺𐐯𐐻 𐐮𐑌𐐻𐐭 𐑄𐐲
𐐔𐐯𐑅𐐨𐑉𐐯𐐻 𐐰𐑊𐑁𐐲𐐺𐐯𐐻.

=head1 METHODS

=head2 transliterate($latin)

Returns the transliteration of the given word into the Deseret alphabet.
If the word is not in the dictionary, returns $latin in uppercase.

𐐡𐐮𐐻𐐨𐑉𐑌𐑆 𐑄𐐲 𐐻𐑉𐐰𐑌𐑅𐑊𐐮𐐻𐐨𐑉𐐩𐑇𐐲𐑌 𐐲𐑂 𐑄𐐲 𐑀𐐮𐑂𐐲𐑌 𐐶𐐨𐑉𐐼 𐐮𐑌𐐻𐐭 𐑄𐐲 𐐔𐐯𐑅𐐨𐑉𐐯𐐻 𐐰𐑊𐑁𐐲𐐺𐐯𐐻.
𐐆𐑁 𐑄𐐲 𐐶𐐨𐑉𐐼 𐐮𐑆 𐑌𐐱𐐻 𐐮𐑌 𐑄𐐲 𐐼𐐮𐐿𐑇𐐲𐑌𐐯𐑉𐐨, 𐑉𐐮𐐻𐐨𐑉𐑌𐑆 $latin 𐐮𐑌 𐐲𐐹𐐨𐑉𐐿𐐩𐑅.

=head2 transliterate_raw($latin)

Similar, but returns undef for unknown words.

𐐝𐐮𐑋𐐲𐑊𐐨𐑉, 𐐺𐐲𐐻 𐑉𐐮𐐻𐐨𐑉𐑌𐑆 undef 𐑁𐐫𐑉 𐐲𐑌𐑌𐐬𐑌 𐐶𐐨𐑉𐐼𐑆.

=head1 FONTS

You will need a Deseret Unicode font to use this module.

𐐧 𐐶𐐮𐑊 𐑌𐐨𐐼 𐐲 𐐔𐐯𐑅𐐨𐑉𐐯𐐻 𐐧𐑌𐐨𐐿𐐬𐐼 𐑁𐐱𐑌𐐻 𐐻𐐭 𐑏𐑅 𐑄𐐮𐑅 𐑋𐐱𐐾𐐭𐑊.

=head1 BUGS

The dictionary is quite small.

One of the vowels ("𐐂") cannot ever be produced because cmudict does not
mark it as a distinct vowel.  If you think some
of the mappings I have made are incorrect, please let me know.

𐐜𐐲 𐐼𐐮𐐿𐑇𐐲𐑌𐐯𐑉𐐨 𐐮𐑆 𐐿𐐶𐐴𐐻 𐑅𐑋𐐫𐑊.

𐐎𐐲𐑌 𐐲𐑂 𐑄𐐲 𐑂𐐵𐐲𐑊𐑆 ("𐐂") 𐐿𐐰𐑌𐐱𐐻 𐐯𐑂𐐨𐑉 𐐺𐐨 𐐹𐑉𐐲𐐼𐐭𐑅𐐻 𐐺𐐮𐐿𐐫𐑆 cmudict 𐐼𐐲𐑆 𐑌𐐱𐐻
𐑋𐐱𐑉𐐿 𐐮𐐻 𐐰𐑆 𐐲 𐐼𐐮𐑅𐐻𐐮𐑍𐐿𐐻 𐑂𐐵𐐲𐑊.  𐐆𐑁 𐑏 𐑃𐐮𐑍𐐿 𐑅𐐲𐑋
𐐲𐑂 𐑄𐐲 𐑋𐐰𐐹𐐮𐑍𐑆 𐐌 𐐸𐐰𐑂 𐑋𐐩𐐼 𐐱𐑉 𐐮𐑌𐐿𐐨𐑉𐐯𐐿𐐻, 𐐹𐑊𐐨𐑆 𐑊𐐯𐐻 𐑋𐐨 𐑌𐐬.

=head1 COPYRIGHT

This Perl module is copyright (C) Thomas Thurman, 2009.
This is free software, and can be used/modified under the same terms as
Perl itself.

𐐜𐐮𐑅 𐐑𐐨𐑉𐑊 𐑋𐐱𐐾𐐭𐑊 𐐮𐑆 𐐿𐐱𐐹𐐨𐑉𐐴𐐻 (C) 𐐓𐐱𐑋𐐲𐑅 𐐛𐐨𐑉𐑋𐐲𐑌, 2009.
𐐜𐐮𐑅 𐐮𐑆 𐑁𐑉𐐨 𐑅𐐫𐑁𐐻𐐶𐐯𐑉, 𐐲𐑌𐐼 𐐿𐐰𐑌 𐐺𐐨 𐑏𐑆𐐼/𐑋𐐱𐐼𐐲𐑁𐐴𐐼 𐐲𐑌𐐼𐐨𐑉 𐑄𐐲 𐑅𐐩𐑋 𐐻𐐨𐑉𐑋𐑆 𐐰𐑆
𐐑𐐨𐑉𐑊 𐐮𐐻𐑅𐐯𐑊𐑁.
