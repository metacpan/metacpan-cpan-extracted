package Lingua::Han::CanonicalPinYin;
use strict;
use warnings;

our $VERSION = 0.04;

use base 'Exporter';

our @EXPORT_OK = 'canonicalize_pinyin';
use utf8;
use Encode;
my @tones = ( "\x{304}", "\x{301}", "\x{30c}", "\x{300}" );
sub canonicalize_pinyin {
    my $pinyin = lc shift;
    $pinyin = decode_utf8( $pinyin ) unless utf8::is_utf8( $pinyin );
    my $tone;
    ($pinyin, $tone) = ( $1, $2 ) if $pinyin =~ /^(.*)(\d)$/;
    return $pinyin if ! defined $tone || $tone == 5;

    if ( $tone < 1 || $tone > 5 ) {
        die "invalid pinyin $pinyin: tone $tone doesn't exist";
    }

    $tone = $tones[$tone-1];
    for my $vowel (qw/a o e iu i u v ü/) {
        if ( $pinyin =~ /$vowel/ ) {
            if ( $vowel eq 'v' ) {
                $pinyin =~ s/v/u\x{308}$tone/;
            }
            else {
                $pinyin =~ s/$vowel/$vowel$tone/;
            }
            last;
        }
    }
    $pinyin =~ s/v/ü/g;

    return $pinyin;
};

1;

__END__

=head1 NAME

Lingua::Han::CanonicalPinYin - Canonical PinYin of Hanzi

=head1 SYNOPSIS

    use Lingua::Han::CanonicalPinYin 'canonicalize_pinyin';
    # $hao is "ha\x{30c}o"
    my $hao = canonicalize_pinyin( 'hao3' );

=head1 DESCRIPTION

This module helps you convert hanzi's pinyin like "hao3" to "ha\x{30c}o".

NOTE: converted value is a utf8 string; 'v' will be replaced by "u\x{308}". 

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

sunnavy  C<< sunnavy@bestpractical.com >>

=head1 LICENCE AND COPYRIGHT

Copyright 2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
