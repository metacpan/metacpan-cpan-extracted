use strict;
use warnings;
package Lingua::AR::Tashkeel;

# ABSTRACT: Subroutines for operating on Arabic vowel marks
our $VERSION = '0.004'; # VERSION

use Exporter 'import';
our @EXPORT_OK = qw(strip prune fix);
use Carp;
use charnames ':full';
use Unicode::Normalize;
use utf8;
use Lingua::AR::Regexp;
use Regexp::CharClasses::Helper;


=pod

=encoding utf8

=head1 NAME

Lingua::AR::Tashkeel - Subroutines for handling Arabic Vowels and Vowel marks


=head1 SYNOPSIS

    use Lingua::AR::Tashkeel qw(strip prune fix);

    # Strip all short vowels
    strip('مَكَرُونَة'); ‎# => مكرونة
    # Heuristic for removing short vowels without causing ambiguity
    prune('فَتَّة');    ‎# => فتّة
    # Heuristic for fixing mixed up short and long vowels
    fix('ماحشي');    ‎# => مَحشي 


=head1 DESCRIPTION
    
Subroutines for working with Arabic long (حروف علة) and short vowels (حركات تشكيل)

=head1 METHODS AND ARGUMENTS

=over 4

=item strip($string)

Strips away all Arabic short vowels (Tashkeel).

=cut

sub strip {
    my $string = NFD shift;
    
    #$string =~ s/(?[ (\p{InArabic} & \p{Mn}) - \N{ARABIC HAMZA ABOVE} ])//g;
    $string =~ s/\p{Lingua::AR::Regexp::IsTashkeel}//gx;

	return NFC $string;
}

=item prune($string)

Heuristic for pruning the short vowels that a native speaker wouldn't write,
as leaving them out wouldn't introduce ambiguity.

This is often preferable to strip, as Shaddas, or Dammas that indicate a passive verb are useful clues that one might want to keep.

=cut

sub InOnesToKeepIn {
    return Regexp::CharClasses::Helper::fmt(
        '+Lingua::AR::Regexp::IsTashkeel',
        '-ARABIC SHADDA',
    );
}

sub prune {
    my $string = NFD shift;
    
    $string =~ s/\p{Lingua::AR::Tashkeel::InOnesToKeepIn}//g;

	return NFC $string;
}

=item fix($string)

Transliterating from a romanized representation of Arabic to actual Arabic script often gives incorrect results regarding short/long vowels.

This subroutine implements a heuristic for fixing such mix ups.

=cut

sub fix {
    my $string = NFD shift;
    
	return $string;
}

1;
__END__

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Lingua-AR-TASHKEEL>

=head1 SEE ALSO

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
