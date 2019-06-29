
package Lingua::IN::TGC;

use Mouse;
use Regexp::Grammars;
use Kavorka -all;
use utf8;

our $VERSION = '2.04';

my @result = ();

method IN::String::X() {
    for my $element ( @{ $self->{Tgc} } ) {
        $element->X();
    }
}

method IN::Tgc::X() {
    (        $self->{S}
          || $self->{Vm}
          || $self->{CH}
          || $self->{CHCvm}
          || $self->{N}
          || $self->{Other}
          || $self->{NT} )->X();
}

method IN::S::X() {
    push @result, $self->{''};
}

method IN::Vm::X() {
    push @result, $self->{V}{''} . $self->{m_}{''};
}

method IN::CH::X() {
    push @result, $self->{''};
}

method IN::CHCvm::X() {
    push @result,
      $self->{CH__}{''} . $self->{C}{''} . $self->{v_}{''} . $self->{m_}{''};
}

method IN::N::X() {
    push @result, $self->{''};
}

method IN::Other::X() {
    push @result, $self->{''};
}

method IN::NT::X() {
    push @result, $self->{''};
}

qr {
    <grammar:  Lingua::IN::TGC::TE>

    <objrule:  IN::Tgc>           <ws: (\s++)*> <S> | <Vm> | <CH> | <CHCvm> | <N> | <Other> | <NT>
    <objrule:  IN::Vm>            <V><m_>
    <objrule:  IN::CHCvm>         <CH__><C><v_><m_>
    <objtoken: IN::CH>            ([క-హౘ-ౚ])(్\b)
    <objtoken: IN::V>             [అ-ఔౠ-ౡ]
    <objtoken: IN::m_>            [ఀ-ఄఽౕౖ]?
    <objtoken: IN::CH__>          (([క-హౘ-ౚ])(్))*
    <objtoken: IN::C>             [క-హౘ-ౚ]
    <objtoken: IN::v_>            [ా-ౌౢౣ]?
    <objtoken: IN::N>             [ా-ౌౢౣఀ-ఄఽౕౖ]
    <objtoken: IN::S>             [ ]
    <objtoken: IN::Other>         [ఀ-౿]
    <objtoken: IN::NT>            [^ఀ-౿]
}xms;

qr {
    <grammar:  Lingua::IN::TGC::DE>

    <objrule:  IN::Tgc>        <ws: (\s++)*> <S> | <Vm> | <CH> | <CHCvm> | <N> | <Other> | <NT>
    <objrule:  IN::Vm>         <V><m_>
    <objrule:  IN::CHCvm>      <CH__><C><v_><m_>
    <objtoken: IN::CH>         ([क-ह])(्\b)
    <objtoken: IN::V>          [ऄ-औॲ-ॷ]
    <objtoken: IN::m_>         [ऀ-ःऽ़]?
    <objtoken: IN::CH__>       (([क-ह])(्))*
    <objtoken: IN::C>          [क-ह]
    <objtoken: IN::v_>         [ा-ौॎॏॕॖॗ]?
    <objtoken: IN::N>          [ा-ौॎॏॕॖॗऀ-ःऽ़]
    <objtoken: IN::S>          [ ]
    <objtoken: IN::Other>      [ऀ-ॿ]
    <objtoken: IN::NT>         [^ऀ-ॿ]
}xms;

qr {
    <grammar:  Lingua::IN::TGC::TA>

    <objrule:  IN::Tgc>        <ws: (\s++)*> <S> | <Vm> | <CH> | <CHCvm> | <N> | <Other> | <NT>
    <objrule:  IN::Vm>         <V><m_>
    <objrule:  IN::CHCvm>      <CH__><C><v_><m_>
    <objtoken: IN::CH>         ([க-ஹ])(்\b)
    <objtoken: IN::V>          [அ-ஔ]
    <objtoken: IN::m_>         [ஂ-ஃௗ]?
    <objtoken: IN::CH__>       (([க-ஹ])(்))*
    <objtoken: IN::C>          [க-ஹ]
    <objtoken: IN::v_>         [ா-ை]?
    <objtoken: IN::N>          [ா-ைஂ-ஃௗ]
    <objtoken: IN::S>          [ ]
    <objtoken: IN::Other>      [ஂ-௺]
    <objtoken: IN::NT>         [^ஂ-௺]
}xms;

qr {
    <grammar:  Lingua::IN::TGC::KN>

    <objrule:  IN::Tgc>        <ws: (\s++)*> <S> | <Vm> | <CH> | <CHCvm> | <N> | <Other> | <NT>
    <objrule:  IN::Vm>         <V><m_>
    <objrule:  IN::CHCvm>      <CH__><C><v_><m_>
    <objtoken: IN::CH>         ([ಕ-ಹೞ])(್\b)
    <objtoken: IN::V>          [ಅ-ಔೠ-ೡ]
    <objtoken: IN::m_>         [ಀ-಄಼ಽೕೖ]?
    <objtoken: IN::CH__>       (([ಕ-ಹೞ])(್))*
    <objtoken: IN::C>          [ಕ-ಹೞ]
    <objtoken: IN::v_>         [ಾ-ೌೢೣ]?
    <objtoken: IN::N>          [ಾ-ೌೢೣఽಀ-಄಼ಽೕೖ]
    <objtoken: IN::S>          [ ]
    <objtoken: IN::Other>      [ಀ-ೲ]
    <objtoken: IN::NT>         [^ಀ-ೲ]
}xms;

qr {
    <grammar:  Lingua::IN::TGC::OR>

    <objrule:  IN::Tgc>        <ws: (\s++)*> <S> | <Vm> | <CH> | <CHCvm> | <N> | <Other> | <NT>
    <objrule:  IN::Vm>         <V><m_>
    <objrule:  IN::CHCvm>      <CH__><C><v_><m_>
    <objtoken: IN::CH>         ([କ-ହଡ଼-ୟ])(୍\b)
    <objtoken: IN::V>          [ଅ-ଔୠୡ]
    <objtoken: IN::m_>         [ଁ-ଃ଼ଽୖୗ]?
    <objtoken: IN::CH__>       (([କ-ହଡ଼-ୟ])(୍))*
    <objtoken: IN::C>          [କ-ହଡ଼-ୟ]
    <objtoken: IN::v_>         [ା-ୈୋୌୢୣ]?
    <objtoken: IN::N>          [ା-ୈୋୌୢୣଁ-ଃ଼ଽୖୗ]
    <objtoken: IN::S>          [ ]
    <objtoken: IN::Other>      [ଁ-୷]
    <objtoken: IN::NT>         [^ଁ-୷]
}xms;

qr {
    <grammar:  Lingua::IN::TGC::OR>

    <objrule:  IN::Tgc>        <ws: (\s++)*> <S> | <Vm> | <CH> | <CHCvm> | <N> | <Other> | <NT>
    <objrule:  IN::Vm>         <V><m_>
    <objrule:  IN::CHCvm>      <CH__><C><v_><m_>
    <objtoken: IN::CH>         ([କ-ହଡ଼-ୟ])(୍\b)
    <objtoken: IN::V>          [ଅ-ଔୠୡ]
    <objtoken: IN::m_>         [ଁ-ଃ଼ଽୖୗ]?
    <objtoken: IN::CH__>       (([କ-ହଡ଼-ୟ])(୍))*
    <objtoken: IN::C>          [କ-ହଡ଼-ୟ]
    <objtoken: IN::v_>         [ା-ୈୋୌୢୣ]?
    <objtoken: IN::N>          [ା-ୈୋୌୢୣଁ-ଃ଼ଽୖୗ]
    <objtoken: IN::S>          [ ]
    <objtoken: IN::Other>      [ଁ-୷]
    <objtoken: IN::NT>         [^ଁ-୷]
}xms;

qr {
    <grammar:  Lingua::IN::TGC::GU>

    <objrule:  IN::Tgc>           <ws: (\s++)*> <S> | <Vm> | <CH> | <CHCvm> | <N> | <Other> | <NT>
    <objrule:  IN::Vm>            <V><m_>
    <objrule:  IN::CHCvm>         <CH__><C><v_><m_>
    <objtoken: IN::CH>            ([క-హౘ-ౚ])(్\b)
    <objtoken: IN::V>             [అ-ఔౠ-ౡ]
    <objtoken: IN::m_>            [ఀ-ఄఽౕౖ]?
    <objtoken: IN::CH__>          (([క-హౘ-ౚ])(్))*
    <objtoken: IN::C>             [క-హౘ-ౚ]
    <objtoken: IN::v_>            [ా-ౌౢౣ]?
    <objtoken: IN::N>             [ా-ౌౢౣఀ-ఄఽౕౖ]
    <objtoken: IN::S>             [ ]
    <objtoken: IN::Other>         [ఀ-౿]
    <objtoken: IN::NT>            [^ఀ-౿]
}xms;

method TGC( Str $lang, Str $string ) {
    my $lang_code = "Lingua::IN::TGC::" . $lang;
    my $parser    = qr {
      <extends: $lang_code>
      <nocontext:>
      <String>
      <objrule:  IN::String>        <[Tgc]>+
    }xms;

    if ( $string =~ $parser ) {
        $/{String}->X();
    }
    return @result;
}

1;
__END__
=encoding utf-8

=head1 NAME

Lingua::IN::TGC - Tailored grapheme clusters for Indic scripts.

=head1 SYNOPSIS

	 use Lingua::IN::TGC;
	 use utf8;
	 binmode STDOUT, ":encoding(UTF-8)";

	 my $tgc = Lingua::IN::TGC->new();
	 my @result = $tgc->TGC("TE", "రాజ్కుమార్రెడ్డి");
	 print $result[1], "\n";


=head1 DESCRIPTION

This module provides one function, TGC.
This function takes two arguments, a language code and a string.


=head1 LANGUAGE CODES

    TE - Telugu
    DE - Devanagari
    TA - Tamil
    KN - Kannada
    OR - Oriya


=head1 TODO

Add support for bengali, malayalam, gujarati, punjabi

=head1 API CHANGE

This 2.xx version is reimplementation of 1.xx module. If you are using 1.xx version please know that newer version api is changed.


=head1 BUGS

Please send me email, if you find any bugs


=head1 AUTHOR

Rajkumar Reddy, mesg.raj@outlook.com


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Rajkumar Reddy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
