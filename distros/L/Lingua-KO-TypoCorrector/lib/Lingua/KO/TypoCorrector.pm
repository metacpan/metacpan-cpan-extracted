package Lingua::KO::TypoCorrector;

use 5.008001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw( to_hangul );
our %EXPORT_TAGS = ( 'all' => [@EXPORT ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.06';

our $en_h = "rRseEfaqQtTdwWczxvg"; 

our $reg_h = "[" . $en_h . "]";

our $en_b = {
    k => 0, #ㅏ
    o => 1, #ㅐ
    i => 2, #ㅑ
    O => 3, #ㅒ
    j => 4, #ㅓ
    p => 5, #ㅖ
    u => 6, #ㅕ
    P => 7, #ㅖ
    h => 8, #ㅗ
    hk => 9, #ㅘ
    ho => 10, #ㅙ
    hl => 11, #ㅚ
    y => 12, #ㅛ
    n => 13, #ㅜ 
    nj => 14, #ㅝ
    np => 15, #ㅞ
    nl => 16, #ㅟ
    b => 17,  #ㅠ
    m => 18,  #ㅡ
    ml => 19, #ㅢ
    l => 20,  #
};

my $reg_b = "hk|ho|hl|nj|np|nl|ml|k|o|i|O|j|p|u|P|h|y|n|b|m|l";

my $en_f = {
    "" => 0,  # 받침없음 
    r  => 1,  # ㄱ    
    R => 2,   # ㄲ
    rt => 3,  # ㄱㅅ    
    s => 4,   # ㄴ
    sw => 5,  # ㄴㅈ
    sg => 6,  # ㄴㅎ
    e => 7,   # ㄷ
    f => 8,   # ㄹ
    fr => 9,  # ㄹㄱ
    fa => 10, # ㄹㅁ
    fq => 11, # ㄹㅂ
    ft => 12, # ㄹㅅ
    fx => 13, # ㄹㅌ
    fv => 14, # ㄹㅍ
    fg => 15, # ㄹㅎ
    a => 16,  # ㅁ
    q => 17,  # ㅂ
    qt => 18, # ㅂㅅ
    t => 19,  # ㅅ
    T => 20,  # ㅆ
    d => 21,  # ㅇ
    w => 22,  # ㅈ
    c => 23,  # ㅊ
    z => 24,  # ㅋ
    x => 25,  # ㅌ
    v => 26,  # ㅍ
    g => 27,  # ㅎ
};  

my $reg_f = "rt|sw|sg|fr|fa|fq|ft|fx|fv|fg|qt|r|R|s|e|f|a|q|t|T|d|w|c|z|x|v|g|";

my $reg_exp = "(".$reg_h.")(".$reg_b.")((?:".$reg_f.")(?=(?:".$reg_h.")(?:".$reg_b."))|(?:".$reg_f."))";

sub to_hangul {
    my $text = shift;
    $text =~ s/$reg_exp/replace($1,$2,$3)/ge;
    return $text;
}

sub replace {
    my ($h,$b,$f) = @_;
    return chr(index($en_h, $h)*21*28 + $en_b->{$b} * 28 + $en_f->{$f} + 44032);
}

1;
__END__

=encoding utf8

=head1 NAME

Lingua::KO::TypoCorrector - Typo Corrector for Korean language in using English

=head1 SYNOPSIS

  use Lingua::KO::TypoCorrector;
  print to_hangul("dkssudgktpdy") # 안녕하세요 (Hello - Korean Language)

=head1 DESCRIPTION

Lingua::KO::TypoCorrector converts all those typos accidently entered in English into Korean.

=head1 AUTHOR

iamseeker,
Jong-jin Lee, E<lt>jeen@perl.krE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by iamseeker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
