package Lingua::Postcodes;
$Lingua::Postcodes::VERSION = '0.003';
use strict;
use warnings;
use utf8;

# ABSTRACT: Returns the names of postcodes/zipcodes

use Exporter 'import';
our @EXPORT_OK = 'name';

my %POSTCODES = (
    AD => { EN => 'Postal code' },
    AF => { EN => 'Postal code' },
    AI => { EN => 'Postcode' },
    AL => { EN => 'Postal code' },
    AM => { EN => 'Postal code' },
    AR => { EN => 'CPA' },
    AS => { EN => 'ZIP codes' },
    AT => { EN => 'PLZ' },
    AU => { EN => 'Postal code' },
    AX => { EN => 'Postnummer' },
    AZ => { EN => 'Post Code' },
    BA => { EN => 'Postal code' },
    BB => { EN => 'Postal code' },
    BD => { EN => 'Postal code' },
    BE => { EN => 'Postcode' },
    BG => { EN => 'Postal code' },
    BH => { EN => 'Postal code' },
    BL => { EN => 'Code postal' },
    BM => { EN => 'Postcode' },
    BN => { EN => 'Postal code' },
    BO => { EN => 'Código postal' },
    BQ => { EN => 'Postal Code' },
    BR => { EN => 'Postal addressing code' },
    BT => { EN => 'Postal code' },
    BY => { EN => 'Postal code' },
    CA => { EN => 'Postal code', FR => 'Code postal' },
    CC => { EN => 'Postal code' },
    CH => { EN => 'Postal Code' },
    CL => { EN => 'Postal code', ES => 'Código postal' },
    CN => { EN => 'Postal code' },
    CO => { EN => 'Postal code', ES => 'Código postal' },
    CR => { EN => 'Postal code', ES => 'Código postal' },
    CU => { EN => 'Postal code', ES => 'Código postal' },
    CV => { EN => 'Postal code' },
    CX => { EN => 'Post Code' },
    CY => { EN => 'Postal code' },
    CZ => { EN => 'Postal code', CZ => 'PSČ' },
    DE => { EN => 'Postal code', DE => 'PLZ' },
    DK => { EN => 'Postal code' },
    DO => { EN => 'Postal code', ES => 'Código postal' },
    DZ => { EN => 'Code postal' },
    EC => { EN => 'Postal code',  ES => 'Código postal' },
    EE => { EN => 'Postal code' },
    EG => { EN => 'Postal code' },
    EH => { EN => 'Postal code' },
    ES => { EN => 'Postal code', ES => 'Código postal' },
    ET => { EN => 'Postal code' },
    FI => { EN => 'Postnummer' },
    FK => { EN => 'Postcode' },
    FM => { EN => 'ZIP codes' },
    FO => { EN => 'Postal code' },
    FR => { EN => 'Postal code', FR => 'Code postal' },
    GA => { EN => 'Postal code' },
    GB => { EN => 'Postcode', FR => '?' },
    GE => { EN => 'Postal code' },
    GF => { EN => 'Code postal' },
    GG => { EN => 'Postcode' },
    GI => { EN => 'Postcode' },
    GL => { EN => 'Postal code' },
    GP => { EN => 'Code postal' },
    GR => { EN => 'Postal code' },
    GS => { EN => 'Postcode' },
    GT => { EN => 'Postal code', ES => 'Código postal' },
    GU => { EN => 'ZIP codes' },
    GW => { EN => 'Postal code' },
    HM => { EN => 'Postal code' },
    HN => { EN => 'Postal code', ES => 'Código postal' },
    HR => { EN => 'Postal code' },
    HT => { EN => 'Code postal' },
    HU => { EN => 'Postal code' },
    ID => { EN => 'Postal code' },
    IE => { EN => 'Eircode' },
    IL => { EN => 'Postal code' },
    IM => { EN => 'Postcode' },
    IN => { EN => 'PIN', HI => 'डाक कोड', TA => 'அஞ்சல் குறியீடு' },
    IO => { EN => 'Postcode' },
    IQ => { EN => 'Postal code' },
    IR => { EN => 'Postal code' },
    IS => { EN => 'Postal code' },
    IT => { EN => 'CAP' },
    JE => { EN => 'Postcode' },
    JM => { EN => 'Postal code' },
    JO => { EN => 'Postal code' },
    JP => { EN => 'Postal Code', JP => '郵便番号' },
    KE => { EN => 'Postal code' },
    KG => { EN => 'Postal code' },
    KH => { EN => 'Postal code' },
    KR => { EN => 'Postal code' },
    KW => { EN => 'Postal code' },
    KY => { EN => 'Postal code' },
    KZ => { EN => 'Postal code' },
    LA => { EN => 'Postal code' },
    LB => { EN => 'Postal code' },
    LI => { EN => 'PLZ' },
    LK => { EN => 'Postal code' },
    LR => { EN => 'Postal code' },
    LS => { EN => 'Postal code' },
    LT => { EN => 'Postal code' },
    LU => { EN => 'Code postal' },
    LV => { EN => 'Postal code' },
    LY => { EN => 'Postal code' },
    MA => { EN => 'Code postal' },
    MC => { EN => 'Code postal' },
    MD => { EN => 'Postal code' },
    ME => { EN => 'Postal code' },
    MF => { EN => 'Code postal' },
    MG => { EN => 'Code postal' },
    MH => { EN => 'ZIP codes' },
    MK => { EN => 'Postal code' },
    MM => { EN => 'Postal code' },
    MN => { EN => 'Postal code' },
    MP => { EN => 'ZIP codes' },
    MQ => { EN => 'Code postal' },
    MT => { EN => 'Postal code' },
    MV => { EN => 'Postal code' },
    MX => { EN => 'Código postal' },
    MY => { EN => 'Postal code' },
    MZ => { EN => 'Postal code' },
    NA => { EN => 'Postal code' },
    NC => { EN => 'Code postal' },
    NE => { EN => 'Code postal' },
    NF => { EN => 'Postal code' },
    NG => { EN => 'Postal code' },
    NI => { EN => 'Postal code', ES => 'Código postal' },
    NL => { EN => 'Postal code' },
    NO => { EN => 'Postal code' },
    NP => { EN => 'Postal code' },
    NZ => { EN => 'Postal code' },
    OM => { EN => 'Postal code' },
    PA => { EN => 'Postal code', ES => 'Código postal' },
    PE => { EN => 'Postal code', ES => 'Código postal' },
    PF => { EN => 'Code postal' },
    PG => { EN => 'Postal code' },
    PH => { EN => 'Postal code' },
    PK => { EN => 'Postal code' },
    PL => { EN => 'Postal code' },
    PM => { EN => 'Code postal' },
    PN => { EN => 'Postcode' },
    PR => { EN => 'ZIP codes' },
    PT => { EN => 'Postal code' },
    PW => { EN => 'ZIP codes' },
    PY => { EN => 'Postal code', ES => 'Código postal' },
    RE => { EN => 'Code postal' },
    RO => { EN => 'Postal code', RO => 'Cod poștal' },
    RS => { EN => 'Postal code', RU => 'Poštanski broj' },
    RU => { EN => 'Postal code' },
    SA => { EN => 'Postal code' },
    SD => { EN => 'Postal code' },
    SE => { EN => 'Postal code' },
    SG => { EN => 'Postal code' },
    SH => { EN => 'Postcode' },
    SI => { EN => 'Postal code' },
    SJ => { EN => 'Postal code' },
    SK => { EN => 'PSČ' },
    SM => { EN => 'CPI' },
    SN => { EN => 'Code postal' },
    SS => { EN => 'Postal code' },
    SV => { EN => 'Código postal' },
    SZ => { EN => 'Postal code' },
    TC => { EN => 'Postcode' },
    TD => { EN => 'Code postal' },
    TH => { EN => 'Postal code' },
    TJ => { EN => 'Postal code' },
    TM => { EN => 'Postal code' },
    TN => { EN => 'Code postal' },
    TR => { EN => 'Postal code' },
    TT => { EN => 'Postal code' },
    TW => { EN => 'Postal code' },
    UA => { EN => 'Postal code' },
    US => { EN => 'ZIP codes' },
    UY => { EN => 'Postal code', ES => 'Código postal' },
    UZ => { EN => 'Postal code' },
    VA => { EN => 'CAP' },
    VC => { EN => 'Postal code' },
    VE => { EN => 'Postal code', ES => 'Código postal' },
    VG => { EN => 'Postal code' },
    VI => { EN => 'ZIP codes' },
    VN => { EN => 'Postal code' },
    WF => { EN => 'Code postal' },
    YT => { EN => 'Code postal' },
    ZA => { EN => 'Postal code' },
    ZM => { EN => 'Postal code' },
);

sub name {
    my $country_code = shift;
    if ( @_ == 0 ) {
        return unless exists $POSTCODES{$country_code};

        return $POSTCODES{$country_code}{'EN'};
    }
    else {
        my $language = shift;
        return unless exists $POSTCODES{$country_code}{$language};

        return $POSTCODES{$country_code}{$language};
    }
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Postcodes - Returns the names of postcodes/zipcodes

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Lingua::Postcodes;

    print 'The English name of a postcode in the UK is:', Lingua::Postcodes::name('GB');
    # The English name of a postcode in the UK is Postcode

    print 'The English name of a postcode in Japan is:', Lingua::Postcodes::name('JP', 'EN');
    # The English name of a postcode in Japan is Postal code

    print 'The Japanese name of a postcode in Japan is:', Lingua::Postcodes::name('JP', 'JP');
    # The Japanese name of a postcode in Japan is 郵便番号

    # Alternate usage:

    use Ligua::Postcodes 'name';
    print 'The Japanese name of a postcode in Japan is:', name('JP', 'JP');
    # The Japanese name of a postcode in Japan is 郵便番号

=head1 DESCRIPTION

This module allows the easy translation of the name of postcodes (postal codes/ zip codes).

Specifically it has been written to give the English name for post codes in other countries.
When working on a multi-national website, where address information is required, this module
helps the developer to put the correct term in the label of a HTML form to match the nation.
For example, when handling the various names for postcodes across Europe.

This module does not parse or handle postcodes themselves; it simply provides a programmatic
way of getting the correct name for postcodes for nations.

=head1 NAME

Lingua::Postcodes - Provide names for postcodes/zipcodes

=head1 VERSION

version 0.003

=head1 AUTHOR

Lance Wicks E<lt>lancew@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016, Lance Wicks. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 AUTHOR

Lance Wicks <lancew@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lance Wicks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
