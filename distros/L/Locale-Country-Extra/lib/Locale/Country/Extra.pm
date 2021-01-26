package Locale::Country::Extra;
use strict;
use warnings;
use utf8;
our $VERSION = '1.0.4';

use Locale::Country qw();
use Locale::Country::Multilingual {use_io_layer => 1};

our %COUNTRY_MAP = (
    "brunei darussalam"                 => "bn",
    "cocos islands"                     => "cc",
    "congo"                             => "cg",
    "curacao"                           => "cw",
    "heard island and mcdonald islands" => "hm",
    "hong kong s.a.r."                  => "hk",
    "korea"                             => "kr",
    "macao s.a.r."                      => "mo",
    "myanmar"                           => "mm",
    "islamic republic of pakistan"      => "pk",
    "palestinian authority"             => "ps",
    "pitcairn"                          => "pn",
    "r\x{e9}union"                      => "re",
    "saint vincent and the grenadines"  => "vc",
    "south georgia"                     => "gs",
    "south georgia & south sandwich"    => "gs",
    "syrian arab republic"              => "sy",
    "taiwan"                            => "tw",
    "u.a.e."                            => "ae",
    "vatican city state"                => "va",
    "virgin islands"                    => "vg"
);

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->{_country_codes} = $self->_build_country_codes;
    $self->{_idd_codes}     = $self->_build_idd_codes;

    return $self;
}

sub country_from_code {
    my ($self, $code) = @_;
    $code = lc $code;

    # we need gb
    $code = 'gb' if $code eq 'uk';

    return $self->_country_codes->{$code};
}

sub code_from_country {
    my ($self, $country) = @_;

    $country =~ s/^\s+|\s+$//g;
    $country = lc $country;

    return $COUNTRY_MAP{$country} if $COUNTRY_MAP{$country};

    my $code = Locale::Country::Multilingual->new()->country2code($country);

    return $code ? lc $code : undef;

}

sub idd_from_code {
    my ($self, $code) = @_;
    $code = lc $code;

    # we need gb
    $code = 'gb' if $code eq 'uk';

    return $self->_idd_codes->{$code};
}

sub get_valid_phone {
    my ($self, $number) = @_;

    return '' if $number =~ /^([0-9])\1{5}/;

    $number =~ s/\D//g;    # Remove non-digits
    $number =~ s/^00//;    # Remove the leading '00'.
    return $number;
}

sub code_from_phone {
    my ($self, $number) = @_;

    if (my $first = $self->codes_from_phone($number)) {
        return lc ${$first}[0];
    }

    return '';
}

sub codes_from_phone {
    my ($self, $number) = @_;

    if (my $phone = $self->get_valid_phone($number)) {
        my %codes = %{$self->_idd_codes};
        return [sort grep { $phone =~ /^$codes{$_}/ } keys %codes];
    }

    return '';
}

sub all_country_names {
    my $self = shift;
    return values %{$self->_country_codes};
}

sub all_country_codes {
    my $self = shift;
    return keys %{$self->_country_codes};
}

sub localized_code2country {
    my ($self, $country_code, $lang) = @_;

    my $lcm = Locale::Country::Multilingual->new();
    return $lcm->code2country($country_code, $lang);
}

sub _country_codes {
    my ($self) = @_;
    return $self->{_country_codes};
}

sub _build_country_codes {
    my $lcm   = Locale::Country::Multilingual->new();
    my @codes = $lcm->all_country_codes();

    my $country_hash = {};
    foreach my $code (@codes) {
        $country_hash->{lc($code)} = $lcm->code2country($code);
    }

    return $country_hash;
}

sub _idd_codes {
    my ($self) = @_;
    return $self->{_idd_codes};
}

sub _build_idd_codes {
    # List is order by zones: https://en.wikipedia.org/wiki/List_of_country_calling_codes#Ordered_by_code
    # TODO: Hardcoding this is not a good idea. IDD's change from time to time.
    return {
        "us" => 1,
        "bs" => 1242,
        "bb" => 1246,
        "ai" => 1264,
        "ag" => 1268,
        "vg" => 1284,
        "vi" => 1340,
        "ky" => 1345,
        "bm" => 1441,
        "gd" => 1473,
        "tc" => 1649,
        "ms" => 1664,
        "mp" => 1670,
        "lc" => 1758,
        "vc" => 1784,
        "pr" => 1787,
        "dm" => 1767,
        "do" => 1809,
        "tt" => 1868,
        "kn" => 1869,
        "jm" => 1876,
        "eg" => 20,
        "eh" => 21,
        "ss" => 211,
        "ma" => 212,
        "dz" => 213,
        "tn" => 216,
        "ly" => 218,
        "gm" => 220,
        "sn" => 221,
        "mr" => 222,
        "ml" => 223,
        "gn" => 224,
        "ci" => 225,
        "bf" => 226,
        "ne" => 227,
        "tg" => 228,
        "bj" => 229,
        "mu" => 230,
        "lr" => 231,
        "sl" => 232,
        "gh" => 233,
        "ng" => 234,
        "td" => 235,
        "cf" => 236,
        "cm" => 237,
        "cv" => 238,
        "st" => 239,
        "gq" => 240,
        "ga" => 241,
        "cg" => 242,
        "cd" => 243,
        "ao" => 244,
        "gw" => 245,
        "io" => 246,
        "sc" => 248,
        "sd" => 249,
        "rw" => 250,
        "et" => 251,
        "so" => 252,
        "dj" => 253,
        "ke" => 254,
        "tz" => 255,
        "ug" => 256,
        "bi" => 257,
        "mz" => 258,
        "zm" => 260,
        "mg" => 261,
        "re" => 262,
        "zw" => 263,
        "na" => 264,
        "mw" => 265,
        "ls" => 266,
        "bw" => 267,
        "sz" => 268,
        "km" => 269,
        "yt" => 262269,
        "za" => 27,
        "sh" => 290,
        "er" => 291,
        "aw" => 297,
        "fo" => 298,
        "gl" => 299,
        "gr" => 30,
        "nl" => 31,
        "be" => 32,
        "fr" => 33,
        "es" => 34,
        "gi" => 350,
        "pt" => 351,
        "lu" => 352,
        "ie" => 353,
        "is" => 354,
        "al" => 355,
        "mt" => 356,
        "cy" => 357,
        "fi" => 358,
        "ax" => 35818,
        "bg" => 359,
        "hu" => 36,
        "lt" => 370,
        "lv" => 371,
        "ee" => 372,
        "md" => 373,
        "am" => 374,
        "by" => 375,
        "ad" => 376,
        "mc" => 377,
        "sm" => 378,
        "va" => 379,
        "ua" => 380,
        "rs" => 381,
        "me" => 382,
        "hr" => 385,
        "si" => 386,
        "ba" => 387,
        "mk" => 389,
        "it" => 39,
        "ro" => 40,
        "li" => 417,
        "ch" => 41,
        "cz" => 420,
        "sk" => 421,
        "at" => 43,
        "gg" => 441481,
        "je" => 441534,
        "im" => 44,
        "gb" => 44,
        "dk" => 45,
        "se" => 46,
        "no" => 47,
        "sj" => 4779,
        "pl" => 48,
        "de" => 49,
        "fk" => 500,
        "gs" => 500,
        "bz" => 501,
        "gt" => 502,
        "sv" => 503,
        "hn" => 504,
        "ni" => 505,
        "cr" => 506,
        "pa" => 507,
        "pm" => 508,
        "ht" => 509,
        "pe" => 51,
        "mx" => 52,
        "cu" => 53,
        "ar" => 54,
        "br" => 55,
        "cl" => 56,
        "co" => 57,
        "ve" => 58,
        "gp" => 590,
        "mf" => 590,
        "bl" => 590,
        "bo" => 591,
        "gy" => 592,
        "ec" => 593,
        "gf" => 594,
        "py" => 595,
        "mq" => 596,
        "sr" => 597,
        "uy" => 598,
        "an" => 599,
        "sx" => 1721,
        "cw" => 5999,
        "my" => 60,
        "au" => 61,
        "cx" => 618,
        "cc" => 6189162,
        "id" => 62,
        "ph" => 63,
        "nz" => 64,
        "pn" => 649,
        "sg" => 65,
        "th" => 66,
        "tl" => 670,
        "gu" => 671,
        "aq" => 672,
        "nf" => 6723,
        "bn" => 673,
        "nr" => 674,
        "pg" => 675,
        "to" => 676,
        "sb" => 677,
        "vu" => 678,
        "fj" => 679,
        "pw" => 680,
        "wf" => 681,
        "ck" => 682,
        "nu" => 683,
        "as" => 684,
        "ws" => 685,
        "ki" => 686,
        "nc" => 687,
        "tv" => 688,
        "pf" => 689,
        "tk" => 690,
        "fm" => 691,
        "mh" => 692,
        "ru" => 7,
        "kz" => 7,
        "jp" => 81,
        "kr" => 82,
        "vn" => 84,
        "kp" => 850,
        "hk" => 852,
        "mo" => 853,
        "kh" => 855,
        "la" => 856,
        "cn" => 86,
        "bd" => 880,
        "tw" => 886,
        "tr" => 90,
        "in" => 91,
        "pk" => 92,
        "af" => 93,
        "lk" => 94,
        "mm" => 95,
        "mv" => 960,
        "lb" => 961,
        "jo" => 962,
        "sy" => 963,
        "iq" => 964,
        "kw" => 965,
        "sa" => 966,
        "ye" => 967,
        "om" => 968,
        "ps" => 970,
        "ae" => 971,
        "il" => 972,
        "bh" => 973,
        "qa" => 974,
        "bt" => 975,
        "mn" => 976,
        "np" => 977,
        "ir" => 98,
        "tj" => 992,
        "tm" => 993,
        "az" => 994,
        "ge" => 995,
        "kg" => 996,
        "uz" => 998,
    };
}

1;

__END__


=encoding utf8

=head1 NAME

Locale::Country::Extra - Standard and IDD codes for Country identification, with Multilingual support

=head1 VERSION

Version 1.0.0

=head1 SYNOPSIS

    use Locale::Country::Extra;

    my $countries = Locale::Country::Extra->new();

    my $c = $countries->country_from_code('au'); # returns 'Australia'
    my $code = $countries->code_from_country('Indonesia'); # returns 'id'
    my $idd = $countries->idd_from_code('in'); # returns 91
    my $code = $countries->code_from_phone('+44 8882220202'); # returns 'gb'

=head1 SUBROUTINES

=head2 new

=head2 all_country_codes

    USAGE
    my @codes = $c->all_country_codes()

    RETURNS
    A list of all country codes

=cut

=head2 all_country_names

    USAGE
    my @names = $c->all_country_names()

    RETURNS
    A list of all country names

=cut

=head2 code_from_country

    USAGE
    my $code = $c->code_from_country($country_name)

    PARAMS
    $country_name => Country Name

    RETURNS
    Country code

    EXTRA
    Extra aliases for country name are supported as below
    %COUNTRY_MAP = (
        "brunei darussalam"                 => "bn",
        "cocos islands"                     => "cc",
        "congo"                             => "cg",
        "heard island and mcdonald islands" => "hm",
        "hong kong s.a.r."                  => "hk",
        "korea"                             => "kr",
        "macao s.a.r."                      => "mo",
        "myanmar"                           => "mm",
        "islamic republic of pakistan"      => "pk",
        "palestinian authority"             => "ps",
        "pitcairn"                          => "pn",
        "réunion"                           => "re",
        "saint vincent and the grenadines"  => "vc",
        "south georgia"                     => "gs",
        "south georgia & south sandwich"    => "gs",
        "syrian arab republic"              => "sy",
        "u.a.e."                            => "ae",
        "vatican city state"                => "va",
        "virgin islands"                    => "vg"
    );

=cut

=head2 get_valid_phone

    USAGE
    my $phone = $c->get_valid_phone($phone_number)

    PARAMS
    $phone_number   => Phone Number

    RETURNS
    A empty string for invalid and the formated phone number for valid numbers

=cut

=head2 code_from_phone

    USAGE
    my $code = $c->code_from_phone($phone_number)

    PARAMS
    $phone_number   => Phone Number

    RETURNS
    The first country code ocurrency

=cut

=head2 codes_from_phone

    USAGE
    my @codes = $c->codes_from_phone($phone_number)

    PARAMS
    $phone_number   => Phone Number

    RETURNS
    All the country codes matching the phone prefix

=cut


=head2 country_from_code

    USAGE
    my $country_name = $c->country_from_code($country_code)

    PARAMS
    $country_code   => Country code

    RETURNS
    Country name

=cut

=head2 idd_from_code

    USAGE
    my $idd = $c->idd_from_code($country_code)

    PARAMS
    $country_code   => Country code

    RETURNS
    IDD code of country

=cut

=head2 localized_code2country

    USAGE
    my $country_name = $c->localized_code2country($country_code, $lang)

    PARAMS
    $country_code   => Country code
    $lang => Language code

    RETURNS
    Localized Country name

=cut

=head1 DEPENDENCIES

=over 4

=item L<Locale::Country>

=item L<Locale::Country::Multilingual>

=back

=head1 SOURCE CODE

L<GitHub|https://github.com/binary-com/perl-Locale-Country-Extra>

=head1 AUTHOR

binary.com, C<< <perl at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-locale-country-extra at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Locale-Country-Extra>.
We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::Country::Extra

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-Country-Extra>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Locale-Country-Extra>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Locale-Country-Extra>

=item * Search CPAN

L<http://search.cpan.org/dist/Locale-Country-Extra/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 binary.com.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

