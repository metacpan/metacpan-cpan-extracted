package Encode::HanConvert;
use 5.006;
use vars qw/$VERSION @EXPORT @EXPORT_OK/;

$VERSION = '0.35';
@EXPORT = qw(
    big5_to_gb trad_to_simp big5_to_simp gb_to_trad big5_to_trad gb_to_simp
    gb_to_big5 simp_to_trad simp_to_big5 trad_to_gb trad_to_big5 simp_to_gb
);

@EXPORT_OK = qw(simple trad);

use base 'Exporter';

if (eval "use Encode qw|encode decode from_to encode_utf8 decode_utf8|; 1") {
    require XSLoader;
    eval { XSLoader::load(__PACKAGE__, $VERSION) }
        or eval {local $^W; require Encode::HanConvert::Perl; Encode::HanConvert::Perl->import; 1}
            or die "Can't load Perl-based Converter: $@";
}
else {
    eval {local $^W; require Encode::HanConvert::Perl; Encode::HanConvert::Perl->import; 1}
        or die "Can't load Perl-based Converter: $@";
}

sub big5_to_gb ($) {
    local $^W; # shuts Encode::HZ's redefine warnings up
    require Encode::CN;

    local $_[0] = $_[0] if defined wantarray;
    from_to($_[0], 'big5-simp' => 'gbk');
    return $_[0];
}

sub gb_to_big5 ($) {
    require Encode::TW;

    local $_[0] = $_[0] if defined wantarray;
    from_to($_[0], 'gbk-trad' => 'big5');
    return $_[0];
}

sub trad_to_simp ($) {
    return decode('trad-simp', encode_utf8($_[0]))
        if (defined wantarray);
    $_[0] = decode('trad-simp', encode_utf8($_[0]));
}

sub simp_to_trad ($) {
    return decode('simp-trad', encode_utf8($_[0]))
        if (defined wantarray);
    $_[0] = decode('simp-trad', encode_utf8($_[0]));
}

sub big5_to_simp ($) {
    return decode('big5-simp', $_[0]) if (defined wantarray);
    $_[0] = decode('big5-simp', $_[0]);
}

sub simp_to_big5 ($) {
    return encode('big5-simp', $_[0]) if (defined wantarray);
    $_[0] = encode('big5-simp', $_[0]);
}

sub gb_to_trad ($) {
    return decode('gbk-trad', $_[0]) if (defined wantarray);
    $_[0] = decode('gbk-trad', $_[0]);
}

sub trad_to_gb ($) {
    return encode('gbk-trad', $_[0]) if (defined wantarray);
    $_[0] = encode('gbk-trad', $_[0]);
}

# For completeness' sake...

sub big5_to_trad ($) {
    require Encode::TW;
    return decode('big5', $_[0]) if (defined wantarray);
    $_[0] = decode('big5', $_[0]);
}

sub trad_to_big5 ($) {
    require Encode::TW;
    return encode('big5', $_[0]) if (defined wantarray);
    $_[0] = encode('big5', $_[0]);
}

sub gb_to_simp ($) {
    local $^W;
    require Encode::CN;
    return decode('gbk', $_[0]) if (defined wantarray);
    $_[0] = decode('gbk', $_[0]);
}

sub simp_to_gb ($) {
    local $^W;
    require Encode::CN;
    return encode('gbk', $_[0]) if (defined wantarray);
    $_[0] = encode('gbk', $_[0]);
}

# Lingua::ZH::HanConvert drop-in replacement -- not exported by default

sub trad { simp_to_trad($_[0]) };
sub simple { trad_to_simp($_[0]) };

1;

__END__

=head1 NAME

Encode::HanConvert - Traditional and Simplified Chinese mappings

=head1 VERSION

This document describes version 0.35 of Encode::HanConvert, released
January 27, 2009.

=head1 SYNOPSIS

As command line utilities:

B<b2g.pl> [ B<-p> ] [ B<-u> ] [ I<inputfile> ...] > I<outputfile>

B<g2b.pl> [ B<-p> ] [ B<-u> ] [[ I<inputfile> ...] > I<outputfile>

In your program:

    # The XS-based implementation needs Encode.pm 1.41;
    # otherwise, autoloads the Perl-based Encode::HanConvert::Perl 
    use Encode::HanConvert; 

    # Conversion between Chinese encodings
    $gbk = big5_to_gb($big5);    # Big5 to GBK
    $big5 = gb_to_big5($gbk);    # GBK to Big5

    # Conversion between Perl's Unicode strings
    $simp = trad_to_simp($trad); # Traditional to Simplified
    $trad = simp_to_trad($simp); # Simplified to Traditional

    # Conversion between Chinese encoding and Unicode strings
    $simp = big5_to_simp($big5); # Big5 to Simplified
    $big5 = simp_to_big5($simp); # Simplified to Big5
    $trad = gb_to_trad($gbk);    # GBK to Traditional
    $gbk = trad_to_gb($trad);    # Traditional to GBK

    # For completeness' sake... (no conversion, just encode/decode)
    $simp = gb_to_simp($gbk);    # GBK to Simplified
    $gbk = simp_to_gb($simp);    # Simplified to GBK
    $trad = big5_to_trad($big5); # Big5 to Traditional
    $big5 = trad_to_big5($trad); # Traditional to Big5

    # All functions may be used in void context to transform $_[0]
    big5_to_gb($string);         # convert $string from Big5 to GBK

    # Drop-in replacement functions for Lingua::ZH::HanConvert
    use Encode::HanConvert qw(trad simple); # not exported by default

    $simp = simple($trad); # Traditional to Simplified
    $trad = trad($simp);   # Simplified to Traditional

=head1 DESCRIPTION

This module is an attempt to solve most common problems occured in
Traditional vs. Simplified Chinese conversion, in an efficient,
flexible way, without resorting to external tools or modules.

If you are using perl 5.7.2 or earlier, all Unicode-related functions
are disabled, and B<Encode::HanConvert::Perl> is automagically loaded
and used instead. In that case, please consult L<Encode::HanConvert::Perl>
instead.

After installing this module, you'll have two additional encoding
formats: C<big5-simp> maps I<Big5> into Unicode's Simplified Chinese
(and vice versa), and C<gbk-trad> maps I<GBK> (also known as I<CP936>)
into Unicode's Traditional Chinese and back.

The module exports various C<xxx_to_yyy> functions by default, where
xxx and yyy are one of C<big5>, C<gb> (i.e. GBK/CP936), C<simp>
(simplified Chinese unicode), or C<trad> (traditional Chinese unicode).

You may also import C<simple> and C<trad>, which are aliases for
C<simp_to_trad> and C<trad_to_simp>; this is provided as a drop-in
replacement for programs using L<Lingua::ZH::HanConvert>.

Since this is built on L<Encode>'s architecture, you may also use
the line discipline syntax to perform the conversion implicitly
(before 5.7.3, you need to use 'cp936' in place of 'gbk'):

    require Encode::CN;
    open BIG5, ':encoding(big5-simp)', 'big5.txt';  # as simplified
    open EUC,  '>:encoding(gbk)',      'gbk.txt';   # as gbk
    print EUC, <BIG5>;

    require Encode::TW;
    open EUC,  ':encoding(gbk-trad)',  'gbk.txt';   # as traditional
    open BIG5, '>:encoding(big5)',     'big5.txt';  # as big-5
    print BIG5, <EUC>;

Or, more interestingly:

=for encoding big5

    use encoding 'big5-simp';
    print "¤¤¤å"; # prints simplified Chinese in unicode

=head1 COMPARISON

Although L<Lingua::ZH::HanConvert> module already provides mapping
between Simplified and Traditional Unicode characters, it depend on
other modules (L<Text::Iconv> or L<Encode>) to provide the necessary
mapping with B<Big5> and B<GBK> encodings.

Also, L<Encode::HanConvert> loads up much faster:

    0.04 real 0.03 user 0.01 sys # Encode::HanConvert
    0.19 real 0.18 user 0.00 sys # Encode::HanConvert::Perl
    1.68 real 1.66 user 0.01 sys # Lingua::ZH::HanConvert (v0.12)

The difference in actual conversion is much more significant. Use 5mb
text of trad => simp as an example:

    0.77 real  0.25 user 0.00 sys # iconv | b2g | iconv
    0.64 real  0.59 user 0.04 sys # Encode::HanConvert b2g.pl -u
   13.79 real 13.69 user 0.02 sys # Lingua::ZH::HanConvert trad2simp (v0.12)

The C<b2g> above refers to Yeung and Lee's I<HanZi Converter>, a C-based
program that maps big5 to gb2312 and back; C<iconv> refers to GNU
libiconv. If you don't mind the overhead of calling an external process,
their result is nearly identical with this module; however, their map
falls short on rarely-used characters and box-drawing symbols.

=head1 CAVEATS

Please note that from version 0.03 and above, this module support the
more expressive range B<GBK> instead of B<EUC-CN>. This may cause
incompatibilities with older fonts. Programs using an earlier version
of this module should rename C<euc-cn-trad> into C<gbk-trad>; sorry for
the inconvenience.

This module does not preserve one-to-many mappings; it blindly chooses
the most frequently used substitutions, instead of presenting the user
multiple choices. This can be remedied by a dictionary-based post
processor that restores the correct character.

As of version 0.05, the mapping from Big5 to GBK is I<complete>: All
displayable Big5 characters are mapped, although substitute characters
are used where there's no direct corresponding characters.

However, there are numerous GBK characters without its Big5 counterparts:
C<grep ¡¼ map/g2b_map.txt> from the distribution directory should show
all of them. Any help on completing this mapping are very appreciated.

=head1 ACKNOWLEDGEMENTS

The conversion table used in this module comes from various sources,
including B<Lingua::ZH::HanConvert> by David Chan, B<hc> by Ricky
Yeung & Fung F. Lee, and B<Doggy Chinese Big5-GB Conversion Master>
from Doggy Digital Creative Inc. (L<http://www.miniasp.com/>), Rei-Li
Chen (rexchen), Unicode consortium's Unicode Character Database
(L<http://www.unicode.org/ucd/>), as well as mappings used in Microsoft Word
2000, Far East edition.

The F<*.ucm> files are checked against test files generated by GNU
libiconv with kind permission from Bruno Haible.

Kudos to Nick Ing-Simmons, Dan Kogai and Jarkko Hietaniemi for 
showing me how to use B<Encode> and PerlIO. Thanks!

=head1 SEE ALSO

L<Encode::HanConvert::Perl>, L<Encode>, L<Lingua::ZH::HanConvert>,
L<Text::Iconv>

The L<b2g.pl> and L<g2b.pl> utilities installed with this module.

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>,
Kuang-che Wu E<lt>kcwu@csie.orgE<gt>.

=head1 COPYRIGHT

Copyright 2002-2009 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.
Copyright 2006 by Kuang-che Wu E<lt>kcwu@csie.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
