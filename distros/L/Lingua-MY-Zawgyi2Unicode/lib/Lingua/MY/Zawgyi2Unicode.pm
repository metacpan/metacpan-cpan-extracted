package Lingua::MY::Zawgyi2Unicode;

use Readonly;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA         = qw(Exporter);
@EXPORT      = qw(isZawgyi isBurmese convert);
@EXPORT_OK   = qw(isZawgyi isBurmese convert);

use strict;
use warnings;

our $VERSION = '0.001';


=head1 NAME

Lingua::MY::Zawgyi2Unicode - providing a module for converting Burmese text in Zawgyi to Unicode (UTF-8).

=head1 VERSION

0.001

=head1 SYNOPSIS

    use Lingua::MY::Zawgyi2Unicode;

    # /.../

    # check if the $string is Burmese (fast operation)
    # and if so, also check if the $string is in
    # zawgyi encoding.

    if (isBurmese($string) and isZawgyi($string)) {
        $string = convert($string);
    }

=head1 DESCRIPTION

A Perl implementation to convert Burmese text in Zawgyi to Unicode (UTF-8). Inspiration, algortithms, and bits of code has been cherry picketed from the L<MUA-Web-Unicode-Converter|https://github.com/sanlinnaing/MUA-Web-Unicode-Converter> project and L<Rabbit-Converter|https://github.com/Rabbit-Converter> project.

=head1 FUNCTIONS

=head2 isBurmese

Check if a string is Burmese text, either Zawgyi or Unicode. Considered a quick operation.

=head2 isZawgui

Check if a string is Zawgyi. This function is slower than isBurmese, so it makes sense to check with isBurmese prior to call this.

=head2 convert

This function convert the supplied string to Unicode and return the result. Do not call this function with a (Burmese) Unicode string, if uncertain of the encoding, check with the above is-functions.

=head1 SOURCE

L<https://github.com/jokke/Lingua-MY-Zawgyi2Unicode> 


=head1 HOMEPAGE

L<https://metacpan.org/release/Lingua-MY-Zawgyi2Unicode> 


=head1 AUTHOR

Joakim Lagerqvist, C<< <jokke at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-my-zawgui2unicode at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-My-Zawgui2Unicode>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Copyright 2009 Joakim Lagerqvist, all rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


Readonly my $zawgyire => qr/
    \x{1031}\x{103b} |      #e+medial ra
    # beginning e or medial ra
    ^\x{1031} | ^\x{103b} |
    # independent vowel, dependent vowel, tone , medial ra wa ha (no ya
    # because of 103a+103b is valid in unicode) , digit ,
    #symbol + medial ra
    [\x{1022}-\x{1030}\x{1032}-\x{1039}\x{103b}-\x{103d}\x{1040}-\x{104f} ] \x{103b} |
    # end with asat
    \x{1039}$ |
    # medial ha + medial wa
    \x{103d}\x{103c} |
    # medial ra + medial wa
    \x{103b}\x{103c} |
    # consonant + asat + ya ra wa ha independent vowel e dot below
    # visarga asat medial ra digit symbol
    [\x{1000}-\x{1021}]\x{1039}[\x{101a}\x{101b}\x{101d}\x{101f}\x{1022}-\x{102a}\x{1031}\x{1037}-\x{1039}\x{103b}\x{1040}-\x{104f}] |
    # II+I II ae
    \x{102e}[\x{102d}\x{103e}\x{1032}] |
    # ae + I II
    \x{1032}[\x{102d}\x{102e}] |
    # I II , II I, I I, II II
    [\x{102d}\x{102e}][\x{102d}\x{102e}] |
    # shan digit + vowel
    [\x{1090}-\x{1099}][\x{102b}-\x{1030}\x{1032}\x{1037}\x{103c}-\x{103e}] |
    # consonant + medial ya + dependent vowel tone asat
    [\x{1000}-\x{102a}]\x{103a}[\x{102c}-\x{102e}\x{1032}-\x{1036}] |
    # independent vowel dependent vowel tone digit + e [ FIXED !!! - not include medial ]
    [\x{1023}-\x{1030}\x{1032}-\x{1039}\x{1040}-\x{104f}]\x{1031} |
    # other shapes of medial ra + consonant not in Shan consonant
    [\x{107e}-\x{1084}][\x{1001}\x{1003}\x{1005}-\x{100f}\x{1012}-\x{1014}\x{1016}-\x{1018}\x{101f}] | 
    # u + asat
    \x{1025}\x{1039} | 
    # eain-dray
    [\x{1081}\x{1083}]\x{108f} | 
    # short na + stack characters
    \x{108f}[\x{1060}-\x{108d}]
    # I II ae dow bolow above + asat typing error
    [\x{102d}-\x{1030}\x{1032}\x{1036}\x{1037}]\x{1039} | 
    # aa + asat awww
    \x{102c}\x{1039} |
    # ya + medial wa
    \x{101b}\x{103c} |
    # non digit + zero + \x{102d} (i vowel) [FIXED!!! rules tested zero + i vowel in numeric usage]
    [^\x{1040}-\x{1049}]\x{1040}\x{102d} |
    # e + zero + vowel
    \x{1031}?\x{1040}[\x{102b}\x{105a}\x{102e}-\x{1030}\x{1032}\x{1036}-\x{1038}] |
    # e + seven + vowel
    \x{1031}?\x{1047}[\x{102c}-\x{1030}\x{1032}\x{1036}-\x{1038}] |
    # U | UU | AI + (zawgyi) dot below
    [\x{102f}\x{1030}\x{1032}]\x{1094} |
    # virama + (zawgyi) medial ra
    \x{1039}[\x{107e}-\x{1084}]
/x;

sub isBurmese {
    my $str = shift;
    if ($str =~ /[\x{1000}-\x{1021}]/) {
        return 1;
    }
    return 0;
}

sub isZawgyi {
    my $str = shift;

    my @lines = split (/[\f\n\r\t\v\x{00a0}\x{1680}\x{180e}\x{2000}-\x{200a}\x{2028}\x{2029}\x{202f}\x{205f}\x{3000}\x{feff}]/, $str);
    for my $line (@lines) {
        my $prepend = '';
        for my $word (split (/\s/, $line)) {
            $word = $prepend.$word;
            $prepend = ' ';
            if ($word =~ /$zawgyire/) {
                return 1;
            }
        }   
    }
    return 0;
}

#From Rabbit
sub convert {
    my ($zawgyi) = @_;
    
    no warnings 'uninitialized';

    $zawgyi =~ s/\x{200b}//g;
    $zawgyi =~ s/(\x{103d}|\x{1087})/\x{103e}/g;
    $zawgyi =~ s/\x{103c}/\x{103d}/g;
    $zawgyi =~ s/(\x{103b}|\x{107e}|\x{107f}|\x{1080}|\x{1081}|\x{1082}|\x{1083}|\x{1084})/\x{103c}/g;
    $zawgyi =~ s/(\x{103a}|\x{107d})/\x{103b}/g;
    $zawgyi =~ s/\x{1039}/\x{103a}/g;
    $zawgyi =~ s/(\x{1066}|\x{1067})/\x{1039}\x{1006}/g;
    $zawgyi =~ s/\x{106a}/\x{1009}/g;
    $zawgyi =~ s/\x{106b}/\x{100a}/g;
    $zawgyi =~ s/\x{106c}/\x{1039}\x{100b}/g;
    $zawgyi =~ s/\x{106d}/\x{1039}\x{100c}/g;
    $zawgyi =~ s/\x{106e}/\x{100d}\x{1039}\x{100d}/g;
    $zawgyi =~ s/\x{106f}/\x{100d}\x{1039}\x{100e}/g;
    $zawgyi =~ s/\x{1070}/\x{1039}\x{100f}/g;
    $zawgyi =~ s/(\x{1071}|\x{1072})/\x{1039}\x{1010}/g;
    $zawgyi =~ s/\x{1060}/\x{1039}\x{1000}/g;
    $zawgyi =~ s/\x{1061}/\x{1039}\x{1001}/g;
    $zawgyi =~ s/\x{1062}/\x{1039}\x{1002}/g;
    $zawgyi =~ s/\x{1063}/\x{1039}\x{1003}/g;
    $zawgyi =~ s/\x{1065}/\x{1039}\x{1005}/g;
    $zawgyi =~ s/\x{1068}/\x{1039}\x{1007}/g;
    $zawgyi =~ s/\x{1069}/\x{1039}\x{1008}/g;
    $zawgyi =~ s/(\x{1073}|\x{1074})/\x{1039}\x{1011}/g;
    $zawgyi =~ s/\x{1075}/\x{1039}\x{1012}/g;
    $zawgyi =~ s/\x{1076}/\x{1039}\x{1013}/g;
    $zawgyi =~ s/\x{1077}/\x{1039}\x{1014}/g;
    $zawgyi =~ s/\x{1078}/\x{1039}\x{1015}/g;
    $zawgyi =~ s/\x{1079}/\x{1039}\x{1016}/g;
    $zawgyi =~ s/\x{107a}/\x{1039}\x{1017}/g;
    $zawgyi =~ s/\x{107c}/\x{1039}\x{1019}/g;
    $zawgyi =~ s/\x{1085}/\x{1039}\x{101c}/g;
    $zawgyi =~ s/\x{1033}/\x{102f}/g;
    $zawgyi =~ s/\x{1034}/\x{1030}/g;
    $zawgyi =~ s/\x{103f}/\x{1030}/g;
    $zawgyi =~ s/\x{1086}/\x{103f}/g;
    $zawgyi =~ s/\x{1036}\x{1088}/\x{1088}\x{1036}/g;
    $zawgyi =~ s/\x{1088}/\x{103e}\x{102f}/g;
    $zawgyi =~ s/\x{1089}/\x{103e}\x{1030}/g;
    $zawgyi =~ s/\x{108a}/\x{103d}\x{103e}/g;
    $zawgyi =~ s/([\x{1000}-\x{1021}])\x{1064}/\x{1004}\x{103a}\x{1039}$1/g;
    $zawgyi =~ s/([\x{1000}-\x{1021}])\x{108b}/\x{1004}\x{103a}\x{1039}$1\x{102d}/g;
    $zawgyi =~ s/([\x{1000}-\x{1021}])\x{108c}/\x{1004}\x{103a}\x{1039}$1\x{102e}/g;
    $zawgyi =~ s/([\x{1000}-\x{1021}])\x{108d}/\x{1004}\x{103a}\x{1039}$1\x{1036}/g;
    $zawgyi =~ s/\x{108e}/\x{102d}\x{1036}/g;
    $zawgyi =~ s/\x{108f}/\x{1014}/g;
    $zawgyi =~ s/\x{1090}/\x{101b}/g;
    $zawgyi =~ s/\x{1091}/\x{100f}\x{1039}\x{100d}/g;
    $zawgyi =~ s/\x{1019}\x{102c}(\x{107b}|\x{1093})/\x{1019}\x{1039}\x{1018}\x{102c}/g;
    $zawgyi =~ s/(\x{107b}|\x{1093})/\x{1039}\x{1018}/g;
    $zawgyi =~ s/(\x{1094}|\x{1095})/\x{1037}/g;
    $zawgyi =~ s/\x{1096}/\x{1039}\x{1010}\x{103d}/g;
    $zawgyi =~ s/\x{1097}/\x{100b}\x{1039}\x{100b}/g;
    $zawgyi =~ s/\x{103c}([\x{1000}-\x{1021}])([\x{1000}-\x{1021}])?/$1\x{103c}$2/g;
    $zawgyi =~ s/([\x{1000}-\x{1021}])\x{103c}\x{103a}/\x{103c}$1\x{103a}/g;
    $zawgyi =~ s/\x{1047}(?=[\x{102c}-\x{1030}\x{1032}\x{1036}-\x{1038}\x{103d}\x{1038}])/\x{101b}/g;
    $zawgyi =~ s/\x{1031}\x{1047}/\x{1031}\x{101b}/g;
    $zawgyi =~ s/\x{1040}(\x{102e}|\x{102f}|\x{102d}\x{102f}|\x{1030}|\x{1036}|\x{103d}|\x{103e})/\x{101d}$1/g;
    $zawgyi =~ s/([^\x{1040}\x{1041}\x{1042}\x{1043}\x{1044}\x{1045}\x{1046}\x{1047}\x{1048}\x{1049}])\x{1040}\x{102b}/$1\x{101d}\x{102b}/g;
    $zawgyi =~ s/([\x{1040}\x{1041}\x{1042}\x{1043}\x{1044}\x{1045}\x{1046}\x{1047}\x{1048}\x{1049}])\x{1040}\x{102b}(?!\x{1038})/$1\x{101d}\x{102b}/g;
    $zawgyi =~ s/^\x{1040}(?=\x{102b})/\x{101d}/g;
    $zawgyi =~ s/\x{1040}\x{102d}(?!\x{0020}?\/)/\x{101d}\x{102d}/g;
    $zawgyi =~ s/([^\x{1040}-\x{1049}])\x{1040}([^\x{1040}-\x{1049}]|[\x{104a}\x{104b}])/$1\x{101d}$2/g;
    $zawgyi =~ s/([^\x{1040}-\x{1049}])\x{1040}(?=[\\f\\n\\r])/$1\x{101d}/g;
    $zawgyi =~ s/([^\x{1040}-\x{1049}])\x{1040}$/$1\x{101d}/g;
    $zawgyi =~ s/\x{1031}([\x{1000}-\x{1021}])(\x{103e})?(\x{103b})?/$1$2$3\x{1031}/g;
    $zawgyi =~ s/([\x{1000}-\x{1021}])\x{1031}([\x{103b}\x{103c}\x{103d}\x{103e}]+)/$1$2\x{1031}/g;
    $zawgyi =~ s/\x{1032}\x{103d}/\x{103d}\x{1032}/g;
    $zawgyi =~ s/\x{103d}\x{103b}/\x{103b}\x{103d}/g;
    $zawgyi =~ s/\x{103a}\x{1037}/\x{1037}\x{103a}/g;
    $zawgyi =~ s/\x{102f}(\x{102d}|\x{102e}|\x{1036}|\x{1037})\x{102f}/\x{102f}$1/g;
    $zawgyi =~ s/\x{102f}\x{102f}/\x{102f}/g;
    $zawgyi =~ s/(\x{102f}|\x{1030})(\x{102d}|\x{102e})/$2$1/g;
    $zawgyi =~ s/(\x{103e})(\x{103b}|\x{103c})/$2$1/g;
    $zawgyi =~ s/\x{1025}(\x{103a}|\x{102c})/\x{1009}$1/g;
    $zawgyi =~ s/\x{1025}\x{102e}/\x{1026}/g;
    $zawgyi =~ s/\x{1005}\x{103b}/\x{1008}/g;
    $zawgyi =~ s/\x{1036}(\x{102f}|\x{1030})/$1\x{1036}/g;
    $zawgyi =~ s/\x{1031}\x{1037}\x{103e}/\x{103e}\x{1031}\x{1037}/g;
    $zawgyi =~ s/\x{1031}\x{103e}\x{102c}/\x{103e}\x{1031}\x{102c}/g;
    $zawgyi =~ s/\x{105a}/\x{102b}\x{103a}/g;
    $zawgyi =~ s/\x{1031}\x{103b}\x{103e}/\x{103b}\x{103e}\x{1031}/g;
    $zawgyi =~ s/(\x{102d}|\x{102e})(\x{103d}|\x{103e})/$2$1/g;
    $zawgyi =~ s/\x{102c}\x{1039}([\x{1000}-\x{1021}])/\x{1039}$1\x{102c}/g;
    $zawgyi =~ s/\x{103c}\x{1004}\x{103a}\x{1039}([\x{1000}-\x{1021}])/\x{1004}\x{103a}\x{1039}$1\x{103c}/g;
    $zawgyi =~ s/\x{1039}\x{103c}\x{103a}\x{1039}([\x{1000}-\x{1021}])/\x{103a}\x{1039}$1\x{103c}/g;
    $zawgyi =~ s/\x{103c}\x{1039}([\x{1000}-\x{1021}])/\x{1039}$1\x{103c}/g;
    $zawgyi =~ s/\x{1036}\x{1039}([\x{1000}-\x{1021}])/\x{1039}$1\x{1036}/g;
    $zawgyi =~ s/\x{1092}/\x{100b}\x{1039}\x{100c}/g;
    $zawgyi =~ s/\x{104e}/\x{104e}\x{1004}\x{103a}\x{1038}/g;
    $zawgyi =~ s/\x{1040}(\x{102b}|\x{102c}|\x{1036})/\x{101d}$1/g;
    $zawgyi =~ s/\x{1025}\x{1039}/\x{1009}\x{1039}/g;
    $zawgyi =~ s/([\x{1000}-\x{1021}])\x{103c}\x{1031}\x{103d}/$1\x{103c}\x{103d}\x{1031}/g;
    $zawgyi =~ s/([\x{1000}-\x{1021}])\x{103b}\x{1031}\x{103d}(\x{103e})?/$1\x{103b}\x{103d}$2\x{1031}/g;
    $zawgyi =~ s/([\x{1000}-\x{1021}])\x{103d}\x{1031}\x{103b}/$1\x{103b}\x{103d}\x{1031}/g;
    $zawgyi =~ s/([\x{1000}-\x{1021}])\x{1031}(\x{1039}[\x{1000}-\x{1021}])/$1$2\x{1031}/g;
    $zawgyi =~ s/\x{1038}\x{103a}/\x{103a}\x{1038}/g;
    $zawgyi =~ s/\x{102d}\x{103a}|\x{103a}\x{102d}/\x{102d}/g;
    $zawgyi =~ s/\x{102d}\x{102f}\x{103a}/\x{102d}\x{102f}/g;
    $zawgyi =~ s/ \x{1037}/\x{1037}/g;
    $zawgyi =~ s/\x{1037}\x{1036}/\x{1036}\x{1037}/g;
    $zawgyi =~ s/\x{102d}\x{102d}/\x{102d}/g;
    $zawgyi =~ s/\x{102e}\x{102e}/\x{102e}/g;
    $zawgyi =~ s/\x{102d}\x{102e}|\x{102e}\x{102d}/\x{102e}/g;
    $zawgyi =~ s/\x{102f}\x{102f}/\x{102f}/g;
    $zawgyi =~ s/\x{102f}\x{102d}/\x{102d}\x{102f}/g;
    $zawgyi =~ s/\x{1037}\x{1037}/\x{1037}/g;
    $zawgyi =~ s/\x{1032}\x{1032}/\x{1032}/g;
    $zawgyi =~ s/\x{1044}\x{1004}\x{103a}\x{1038}/\x{104e}\x{1004}\x{103a}\x{1038}/g;
    $zawgyi =~ s/\x{103a}\x{103a}/\x{103a}/g;
    $zawgyi =~ s/ \x{1037}/\x{1037}/g;

    return $zawgyi;
}

1;
