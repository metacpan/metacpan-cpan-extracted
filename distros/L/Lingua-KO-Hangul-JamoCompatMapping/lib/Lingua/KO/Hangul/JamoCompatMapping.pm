use strict;
use warnings;
package Lingua::KO::Hangul::JamoCompatMapping;
{
  $Lingua::KO::Hangul::JamoCompatMapping::VERSION = '0.004';
}

# ABSTRACT: provide a function that maps Hangul Jamo into Hangul Compatibility code


use Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = ();
our @EXPORT_OK = qw/%onset_to_compat %nucleus_to_compat %coda_to_compat %jamo_to_compat jamo_to_compat/;

# onset
my %onset_to_compat = (
    "\x{1100}"  => "\x{3131}",      #ㄱ
    "\x{1101}"  => "\x{3132}",      #ㄲ
    "\x{1102}"  => "\x{3134}",      #ㄴ
    "\x{1103}"  => "\x{3137}",      #ㄷ
    "\x{1104}"  => "\x{3138}",      #ㄸ
    "\x{1105}"  => "\x{3139}",      #ㄹ
    "\x{1106}"  => "\x{3141}",      #ㅁ
    "\x{1107}"  => "\x{3142}",      #ㅂ
    "\x{1108}"  => "\x{3143}",      #ㅃ
    "\x{1109}"  => "\x{3145}",      #ㅅ
    "\x{110A}"  => "\x{3146}",      #ㅆ
    "\x{110B}"  => "\x{3147}",      #ㅇ
    "\x{110C}"  => "\x{3148}",      #ㅈ
    "\x{110D}"  => "\x{3149}",      #ㅉ
    "\x{110E}"  => "\x{314A}",      #ㅊ
    "\x{110F}"  => "\x{314B}",      #ㅋ

    "\x{1110}"  => "\x{314C}",      #ㅌ
    "\x{1111}"  => "\x{314D}",      #ㅍ
    "\x{1112}"  => "\x{314E}",      #ㅎ
);

# nucleus
my %nucleus_to_compat = map { chr($_) => chr($_ + 0x1FEE) } ( 0x1161 .. 0x1175 );

# coda
my %coda_to_compat = (
    "\x{11A8}"  => "\x{3131}",      # ㄱ
    "\x{11A9}"  => "\x{3132}",      # ㄲ
    "\x{11AA}"  => "\x{3133}",      # ᆨᆺ
    "\x{11AB}"  => "\x{3134}",      # ㄴ
    "\x{11AC}"  => "\x{3135}",      # ᆫᆽ
    "\x{11AD}"  => "\x{3136}",      # ᆫᇂ
    "\x{11AE}"  => "\x{3137}",      # ㄷ
    "\x{11AF}"  => "\x{3139}",      # ㄹ
    
    "\x{11B0}"  => "\x{313A}",      # ᆯᆨ
    "\x{11B1}"  => "\x{313B}",      # ᆯᆷ
    "\x{11B2}"  => "\x{313C}",      # ᆯᆸ
    "\x{11B3}"  => "\x{313D}",      # ᆯㅅ
    "\x{11B4}"  => "\x{313E}",      # ᆯᇀ
    "\x{11B5}"  => "\x{313F}",      # ᆯᇁ
    "\x{11B6}"  => "\x{3140}",      # ᆯᇂ
    "\x{11B7}"  => "\x{3141}",      # ᆷ
    "\x{11B8}"  => "\x{3142}",      # ᆸ
    "\x{11B9}"  => "\x{3144}",      # ᆸᆺ
    "\x{11BA}"  => "\x{3145}",      # ᆺ
    "\x{11BB}"  => "\x{3146}",      # ᆻ
    "\x{11BC}"  => "\x{3147}",      # ᆼ
    "\x{11BD}"  => "\x{3148}",      # ᆽ
    "\x{11BE}"  => "\x{314A}",      # ᆾ
    "\x{11BF}"  => "\x{314B}",      # ᆿ
    
    "\x{11C0}"  => "\x{314C}",      # ᇀ 
    "\x{11C1}"  => "\x{314D}",      # ᇁ
    "\x{11C2}"  => "\x{314E}",      # ᇂ
);

# full set
my %jamo_to_compat = ( %onset_to_compat, %nucleus_to_compat, %coda_to_compat );


sub jamo_to_compat {
    return $jamo_to_compat{$_[0]};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::KO::Hangul::JamoCompatMapping - provide a function that maps Hangul Jamo into Hangul Compatibility code

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Lingua::KO::Hangul::JamoCompatMapping qw/jamo_to_compat/;

    # HANGUL CHOSEONG KIYEOK (\x{1100}) => HANGUL LETTER KIYEOK (\x{3131})
    $letter = jamo_to_compat("\x{1100}");
    # HANGUL JONGSEONG KIYEOK (\x{11A8}) => HANGUL LETTER KIYEOK (\x{3131})
    $letter = jamo_to_compat("\x{11A8}");

=head1 DESCRIPTION

Function B<jamo_to_compat()> maps "Hangul Jamo" to "Hangul Compatibility Jamo" and
returns compatibility jamo code.

It receives as an argument a codepoint of a single Hangul Jamo, and returns
the codepoint of a Hangul Compatibility Jamo that responds to the argument.
It returns undefined value in case there is not the mapping for given argument.

Up to now, only consonants and vowels that are used in the present-day are mapped.

  CHOSEONG  (the initial sound)   \x{1100} .. \x{1112}
  JUNGSEONG (the medial sound)    \x{1161} .. \x{1175}
  JONGSEONG (the final sound)     \x{11A8} .. \x{11C2}

Note that two consonants, one in CHOSEONG and the other in JONGSEONG, may be mapped
into the same codepoint. For example, both C<\x{1100}>(CHOSEONG KIYEOK) and C<\x{11A8}>
(JONGSEONG KIYEOK) are mapped to the same codepoint C<\x{3131}>(LETTER KIYEOK).

This module can be used to match a sequence of Hangul letters over a Korean word.
For example, C<decomposeSyllable()> from L<Lingua::KO::Hangul::Util>
decomposes a Hangul syllable to a sequence of conjoining letters. These letters are
in the range of Hangul Jamo in Unicode. However, when another sequence of letters
are provided via standard input or network(CGI, etc), they might be in the range of
Hangul Compatibility Jamo. In this case, you need to convert the former sequence into
the sequence of Compatibility Jamo to examine whether two sequence match or not.

=head1 SEE ALSO

=over 4

=item L<Lingua::KO::Hangul::Util>

=back

=head1 AUTHOR

Geunyoung Park <gypark@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Geunyoung Park.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
