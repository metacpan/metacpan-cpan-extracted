package Geo::UK::Postcode::Regex;

use strict;
use warnings;

use Geo::UK::Postcode::Regex::Hash;

use base 'Exporter';
our @EXPORT_OK = qw( is_valid_pc is_strict_pc is_lax_pc %REGEXES );

our $VERSION = '0.017';

=encoding utf-8

=head1 NAME

Geo::UK::Postcode::Regex - regular expressions for handling British postcodes

=head1 SYNOPSIS

See L<Geo::UK::Postcode::Regex::Simple> for an alternative interface.

    use Geo::UK::Postcode::Regex;

    ## REGULAR EXPRESSIONS

    my $lax_re    = Geo::UK::Postcode::Regex->regex;
    my $strict_re = Geo::UK::Postcode::Regex->strict_regex;
    my $valid_re  = Geo::UK::Postcode::Regex->valid_regex;

    # matching only
    if ( $foo =~ $lax_re )    {...}
    if ( $foo =~ $strict_re ) {...}
    if ( $foo =~ $valid_re )  {...}

    # matching and using components - see also parse()
    if ( $foo =~ $lax_re ) {
        my ( $area, $district, $sector, $unit ) = ( $1, $2, $3, $4 );
        my $subdistrict = $district =~ s/([A-Z])$// ? $1 : undef;
        ...
    }
    if ( $foo =~ $strict_re ) {
        my ( $area, $district, $sector, $unit ) = ( $1, $2, $3, $4 );
        my $subdistrict = $district =~ s/([A-Z])$// ? $1 : undef;
        ...
    }
    if ( $foo =~ $valid_re ) {
        my ( $outcode, $sector, $unit ) = ( $1, $2, $3 );
        ...
    }


    ## VALIDATION METHODS

    use Geo::UK::Postcode::Regex qw( is_valid_pc is_strict_pc is_lax_pc );

    if (is_valid_pc("GE0 1UK")) {
        ...
    }
    if (is_strict_pc("GE0 1UK")) {
        ...
    }
    if (is_lax_pc("GE0 1UK")) {
        ...
    }


    ## PARSING

    my $parsed = Geo::UK::Postcode::Regex->parse("WC1H 9EB");

    # returns:
    # {   area             => 'WC',
    #     district         => '1',
    #     subdistrict      => 'H',
    #     sector           => '9',
    #     unit             => 'EB',
    #     outcode          => 'WC1H',
    #     incode           => '9EB',
    #     valid            => 1,
    #     strict           => 1,
    #     partial          => 0,
    #     non_geographical => 0,
    #     bfpo             => 0,
    # }

    # strict parsing (only valid characters):
    ...->parse( $pc, { strict => 1 } )

    # valid outcodes only
    ...->parse( $pc, { valid => 1 } )

    # match partial postcodes, e.g. 'WC1H', 'WC1H 9' - see below
    ...->parse( $pc, { partial => 1 } )


    ## PARSING PARTIAL POSTCODES

    # outcode (district) only
    my $parsed = Geo::UK::Postcode::Regex->parse( "AB10", { partial => 1 } );

    # returns:
    # {   area             => 'AB',
    #     district         => '10',
    #     subdistrict      => undef,
    #     sector           => undef,
    #     unit             => undef,
    #     outcode          => 'AB10',
    #     incode           => undef,
    #     valid            => 1,
    #     strict           => 1,
    #     partial          => 1,
    #     non_geographical => 0,
    #     bfpo             => 0,
    # }

    # sector only
    my $parsed = Geo::UK::Postcode::Regex->parse( "AB10 1", { partial => 1 } );

    # returns:
    # {   area             => 'AB',
    #     district         => '10',
    #     subdistrict      => undef,
    #     sector           => 1,
    #     unit             => undef,
    #     outcode          => 'AB10',
    #     incode           => '1',
    #     valid            => 1,
    #     strict           => 1,
    #     partial          => 1,
    #     non_geographical => 0,
    #     bfpo             => 0,
    # }


    ## EXTRACT OUTCODE FROM POSTCODE

    my $outcode = Geo::UK::Postcode::Regex->outcode("AB101AA"); # returns 'AB10'

    my $outcode = Geo::UK::Postcode::Regex->outcode( $postcode, { valid => 1 } )
        or die "Invalid postcode";


    ## EXTRACT POSTCODES FROM TEXT

    # \%options as per parse, excluding partial
    my @extracted = Geo::UK::Postcode::Regex->extract( $text, \%options );


    ## POSTTOWNS
    my @posttowns = Geo::UK::Postcode::Regex->outcode_to_posttowns($outcode);


    ## OUTCODES
    my @outcodes = Geo::UK::Postcode::Regex->posttown_to_outcodes($posttown);


=head1 DESCRIPTION

Parsing UK postcodes with regular expressions (aka Regexp). This package has
been separated from L<Geo::UK::Postcode> so it can be installed and used with
fewer dependencies.

Can handle partial postcodes (just the outcode or sector) and can test
against valid characters and currently valid outcodes.

Also can determine the posttown(s) from a postcode.

Districts and post town information taken from:
L<https://en.wikipedia.org/wiki/Postcode_districts>

=head1 IMPORTANT CHANGES FOR VERSION 0.014

Please note that various bugfixes have changed the following:

=over

=item *

Unanchored regular expressions no longer match valid postcodes within invalid
ones.

=item *

Unanchored regular expressions in partial mode now can match a valid or strict
outcode with an invalid incode.

=back

Please get in touch if you have any questions.

See L<Geo::UK::Postcode::Regex::Simple> for other changes affecting the Simple
interface.

=head1 NOTES AND LIMITATIONS

When parsing a partial postcode, whitespace may be required to separate the
outcode from the sector.

For example the sector 'B1 1' cannot be distinguished from the district 'B11'
without whitespace. This is not a problem when parsing full postcodes.

=cut

## REGULAR EXPRESSIONS

my $AREA1 = 'ABCDEFGHIJKLMNOPRSTUWYZ';    # [^QVX]
my $AREA2 = 'ABCDEFGHKLMNOPQRSTUVWXY';    # [^IJZ]

my $SUBDISTRICT1 = 'ABCDEFGHJKPSTUW';      # for single letter areas
my $SUBDISTRICT2 = 'ABEHMNPRVWXY';         # for two letter areas

my $UNIT1 = 'ABDEFGHJLNPQRSTUWXYZ';        # [^CIKMOV]
my $UNIT2 = 'ABDEFGHJLNPQRSTUWXYZ';        # [^CIKMOV]

our %COMPONENTS = (
    strict => {
        area     => "[$AREA1][$AREA2]?",
        district => qq% (?:
                            [0-9][0-9]?
            | (?<![A-Z]{2}) [0-9][$SUBDISTRICT1]?
            | (?<=[A-Z]{2}) [0-9][$SUBDISTRICT2]
        ) %,
        sector => '[0-9]',
        unit   => "[$UNIT1][$UNIT2]",
        blank  => '',
    },
    lax => {
        area     => '[A-Z]{1,2}',
        district => '[0-9](?:[0-9]|[A-Z])?',
        sector   => '[0-9]',
        unit     => '[A-Z]{2}',
    },
);

my %BASE_REGEXES = (
    full          => ' %s %s     \s* %s    %s       ',
    partial       => ' %s %s (?: \s* %s (?:%s)? ) ? ',
);

my ( %POSTTOWNS, %OUTCODES );

tie our %REGEXES, 'Geo::UK::Postcode::Regex::Hash', _fetch => sub {
    my ($key) = @_;

    _outcode_data() if $key =~ m/valid/ && !%OUTCODES;

    my $type = $key =~ m/lax/ ? 'lax' : 'strict';

    my $components = $Geo::UK::Postcode::Regex::COMPONENTS{$type};

    my @comps
        = $key =~ m/valid/
        ? @{$components}{qw( outcodes blank sector unit )}
        : @{$components}{qw( area district sector unit )};

    @comps = map { $_ ? "($_)" : $_ } @comps if $key =~ m/captures/;

    my $size = $key =~ m/partial/ ? 'partial' : 'full';

    my $re = sprintf( $BASE_REGEXES{$size}, @comps );

    if ( $key =~ m/anchored/ ) {
        $re = '^' . $re . '$';

    } elsif ( $key =~ m/extract/ ) {
        $re = '(?:[^0-9A-Z]|\b) (' . $re . ') (?:[^0-9A-Z]|\b)';

    } else {
        $re = '(?:[^0-9A-Z]|\b) ' . $re . ' (?:[^0-9A-Z]|\b)';
    }

    return $key =~ m/case-insensitive/ ? qr/$re/ix : qr/$re/x;
};

## OUTCODE AND POSTTOWN DATA

sub _outcode_data {
    my %area_districts;

    # get the original position in the DATA File Handle
    my $orig_position = tell( DATA );
    # Get outcodes from __DATA__
    while ( my $line = <DATA> ) {
        next unless $line =~ m/\w/;
        chomp $line;
        my ( $outcode, $non_geographical, @posttowns ) = split /,/, $line;

        push @{ $POSTTOWNS{$_} }, $outcode foreach @posttowns;
        $OUTCODES{$outcode} = {
            posttowns        => \@posttowns,
            non_geographical => $non_geographical,
        };
    }
    # Reset position of DATA File Handle for re-reading
    seek DATA, $orig_position, 0;

    # Add in BX non-geographical outcodes
    foreach ( 1 .. 99 ) {
        $OUTCODES{ 'BX' . $_ } = {
            posttowns        => [],
            non_geographical => 1,
        };
    }

    foreach my $outcode ( sort keys %OUTCODES ) {
        my ( $area, $district )
            = $outcode =~ $REGEXES{strict_partial_anchored_captures}
            or next;

        $district = " $district" if length $district < 2;

        push @{ $area_districts{$area}->{ substr( $district, 0, 1 ) } },
            substr( $district, 1, 1 );
    }

    $Geo::UK::Postcode::Regex::COMPONENTS{strict}->{outcodes} = '(?: ' . join(
        "|\n",
        map {
            my $area = $_;
            sprintf(
                "%s (?:%s)",    #
                $area,
                join(
                    ' | ',
                    map {
                        sprintf( "%s[%s]",
                            $_, join( '', @{ $area_districts{$area}->{$_} } ) )
                        }       #
                        sort { $a eq ' ' ? 1 : $b eq ' ' ? -1 : $a <=> $b }
                        keys %{ $area_districts{$area} }
                )
                )
        } sort keys %area_districts
    ) . ' )';

}

=head1 VALIDATION METHODS

The following methods are for validating postcodes to various degrees.

L<Geo::UK::Postcode::Regex::Simple> may provide a more convenient way of using
and customising these.

=head2 regex, strict_regex, valid_regex

Return regular expressions to parse postcodes and capture the constituent
parts: area, district, sector and unit (or outcode, sector and unit in the
case of C<valid_regex>).

C<strict_regex> checks that the postcode only contains valid characters
according to the postcode specifications.

C<valid_regex> checks that the outcode currently exists.

=head2 regex_partial, strict_regex_partial, valid_regex_partial

As above, but matches on partial postcodes of just the outcode
or sector

=cut

sub valid_regex_partial  { $REGEXES{valid_partial_anchored_captures} }
sub strict_regex_partial { $REGEXES{strict_partial_anchored_captures} }
sub regex_partial        { $REGEXES{lax_partial_anchored_captures} }
sub valid_regex          { $REGEXES{valid_anchored_captures} }
sub strict_regex         { $REGEXES{strict_anchored_captures} }
sub regex                { $REGEXES{lax_anchored_captures} }


=head2 is_valid_pc, is_strict_pc, is_lax_pc

    if (is_valid_pc( "AB1 2CD" ) ) { ... }

Alternative way to access the regexes.

=cut

sub is_valid_pc {
    my $pc = @_ > 1 ? $_[1] : $_[0]; # back-compat: can call as class method
    return $pc =~ $REGEXES{valid_anchored} ? 1 : 0
}
sub is_strict_pc {
    my $pc = @_ > 1 ? $_[1] : $_[0]; # back-compat: can call as class method
    return $pc =~ $REGEXES{strict_anchored} ? 1 : 0
}
sub is_lax_pc {
    my $pc = @_ > 1 ? $_[1] : $_[0]; # back-compat: can call as class method
    return $pc =~ $REGEXES{lax_anchored} ? 1 : 0
}

=head1 PARSING METHODS

The following methods are for parsing postcodes or strings containing postcodes.

=head2 PARSING_OPTIONS

The parsing methods can take the following options, passed via a hashref:

=over

=item strict

Postcodes must not contain invalid characters according to the postcode
specification. For example a 'Q' may not appear as the first character.

=item valid

Postcodes must contain an outcode (area + district) that currently exists, in
addition to conforming to the C<strict> definition.

Returns false if string is not a currently existing outcode.

=item partial

Allows partial postcodes to be matched. In practice this means either an outcode
( area and district ) or an outcode together with the sector.

=back

=head2 extract

    my @extracted = Geo::UK::Postcode::Regex->extract( $string, \%options );

Returns a list of full postcodes extracted from a string.

=cut

# TODO need to/can do partial?

sub extract {
    my ( $class, $string, $options ) = @_;

    _outcode_data() unless %OUTCODES;

    my $key
        = $options->{valid}  ? 'valid'
        : $options->{strict} ? 'strict'
        :                      'lax';

    $key .= '_case-insensitive' if $options->{'case-insensitive'};
    $key .= '_extract';

    my @extracted = $string =~ m/$REGEXES{$key}/g;

    return map {uc} @extracted;
}

=head2 parse

    my $parsed = Geo::UK::Postcode::Regex->parse( $pc, \%options );

Returns hashref of the constituent parts - see SYNOPSIS. Missing parts will be
set as undefined.

=cut

sub parse {
    my ( $class, $string, $options ) = @_;

    $options ||= {};

    $string = uc $string if $options->{'case-insensitive'};

    my $re
        = $options->{partial}
        ? 'partial_anchored_captures'
        : 'anchored_captures';

    my ( $area, $district, $sector, $unit ) = $string =~ $REGEXES{"strict_$re"};

    my $strict = $area ? 1 : 0;    # matched strict?

    unless ($strict) {
        return if $options->{strict};

        # try lax regex
        ( $area, $district, $sector, $unit ) = $string =~ $REGEXES{"lax_$re"}
            or return;
    }

    return unless $unit || $options->{partial};

    return unless defined $district;

    my $outcode      = $area . $district;
    my $outcode_data = $class->outcodes_lookup->{$outcode};

    return if $options->{valid} && !$outcode_data;

    my $subdistrict = $district =~ s/([A-Z])$// ? $1 : undef;

    my $incode = $unit ? "$sector$unit" : $sector ? $sector : undef;

    return {
        area        => $area,
        district    => $district,
        subdistrict => $subdistrict,
        sector      => $sector,
        unit        => $unit,
        outcode     => $outcode,
        incode      => $incode,

        strict  => $strict,
        partial => $unit ? 0 : 1,
        valid   => $outcode_data && $strict ? 1 : 0,

        $outcode_data->{non_geographical} ? ( non_geographical => 1 ) : (),
        $outcode eq "BF1"                 ? ( bfpo             => 1 ) : (),
    };
}

=head2 outcode

    my $outcode = Geo::UK::Postcode::Regex->outcode( $pc, \%options );

Extract the outcode (area and district) from a postcode string. Will work on
full or partial postcodes.

=cut

sub outcode {
    my ( $class, $string, $options ) = @_;

    my $parsed = $class->parse( $string, { partial => 1, %{ $options || {} } } )
        or return;

    return $parsed->{outcode};
}

=head1 LOOKUP METHODS

=head2 outcode_to_posttowns

    my ( $posttown1, $posttown2, ... )
        = Geo::UK::Postcode::Regex->outcode_to_posttowns($outcode);

Returns posttown(s) for supplied outcode.

Note - most outcodes will only have one posttown, but some are shared between
two posttowns.

=cut

sub outcode_to_posttowns {
    my ( $class, $outcode ) = @_;

    my $data = $class->outcodes_lookup->{$outcode};

    return @{ $data ? $data->{posttowns} : [] };
}

=head2 posttown_to_outcodes

    my @outcodes = Geo::UK::Postcode::Regex->posttown_to_outcodes($posttown);

Returns the outcodes covered by a posttown. Note some outcodes are shared
between posttowns.

=cut

sub posttown_to_outcodes {
    my ( $class, $posttown ) = @_;

    return @{ $class->posttowns_lookup->{ $posttown || '' } || [] };
}

=head2 outcodes_lookup

    my %outcodes = %{ Geo::UK::Postcode::Regex->outcodes_lookup };
    print "valid outcode" if $outcodes{$outcode};
    my @posttowns = @{ $outcodes{$outcode} };

Hashref of outcodes to posttown(s);

=head2 posttowns_lookup

    my %posttowns = %{ Geo::UK::Postcode::Regex->posttowns_lookup };
    print "valid posttown" if $posttowns{$posttown};
    my @outcodes = @{ $[posttowns{$posttown} };

Hashref of posttown to outcode(s);

=cut

sub outcodes_lookup {
    my $class = shift;

    _outcode_data() unless %OUTCODES;

    return \%OUTCODES;
}

sub posttowns_lookup {
    my $class = shift;

    _outcode_data() unless %POSTTOWNS;

    return \%POSTTOWNS;
}

=head1 SEE ALSO

=over

=item *

L<Geo::UK::Postcode> - companion package, provides Postcode objects

=item *

L<Geo::Address::Mail::UK>

=item *

L<Geo::Postcode>

=item *

L<Data::Validation::Constraints::Postcode>

=item *

L<CGI::Untaint::uk_postcode>

=item *

L<Form::Validator::UKPostcode>

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/mjemmeson/geo-uk-postcode-regex/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/mjemmeson/geo-uk-postcode-regex>

    git clone git://github.com/mjemmeson/geo-uk-postcode-regex.git

=head1 AUTHOR

Michael Jemmeson E<lt>mjemmeson@cpan.orgE<gt>

=head1 CONTRIBUTORS

=over

=item *

Tom Bloor C<TBSLIVER>

=back

=head1 COPYRIGHT

Copyright 2015-2017 Michael Jemmeson

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__DATA__
AB10,0,ABERDEEN
AB11,0,ABERDEEN
AB12,0,ABERDEEN
AB13,0,MILLTIMBER
AB14,0,PETERCULTER
AB15,0,ABERDEEN
AB16,0,ABERDEEN
AB21,0,ABERDEEN
AB22,0,ABERDEEN
AB23,0,ABERDEEN
AB24,0,ABERDEEN
AB25,0,ABERDEEN
AB30,0,LAURENCEKIRK
AB31,0,BANCHORY
AB32,0,WESTHILL
AB33,0,ALFORD
AB34,0,ABOYNE
AB35,0,BALLATER
AB36,0,STRATHDON
AB37,0,BALLINDALLOCH
AB38,0,ABERLOUR
AB39,0,STONEHAVEN
AB41,0,ELLON
AB42,0,PETERHEAD
AB43,0,FRASERBURGH
AB44,0,MACDUFF
AB45,0,BANFF
AB51,0,INVERURIE
AB52,0,INSCH
AB53,0,TURRIFF
AB54,0,HUNTLY
AB55,0,KEITH
AB56,0,BUCKIE
AB99,1,ABERDEEN
AL1,0,ST. ALBANS
AL2,0,ST. ALBANS
AL3,0,ST. ALBANS
AL4,0,ST. ALBANS
AL5,0,HARPENDEN
AL6,0,WELWYN
AL7,0,WELWYN,WELWYN GARDEN CITY
AL8,0,WELWYN GARDEN CITY
AL9,0,HATFIELD
AL10,0,HATFIELD
B1,0,BIRMINGHAM
B2,0,BIRMINGHAM
B3,0,BIRMINGHAM
B4,0,BIRMINGHAM
B5,0,BIRMINGHAM
B6,0,BIRMINGHAM
B7,0,BIRMINGHAM
B8,0,BIRMINGHAM
B9,0,BIRMINGHAM
B10,0,BIRMINGHAM
B11,0,BIRMINGHAM
B12,0,BIRMINGHAM
B13,0,BIRMINGHAM
B14,0,BIRMINGHAM
B15,0,BIRMINGHAM
B16,0,BIRMINGHAM
B17,0,BIRMINGHAM
B18,0,BIRMINGHAM
B19,0,BIRMINGHAM
B20,0,BIRMINGHAM
B21,0,BIRMINGHAM
B23,0,BIRMINGHAM
B24,0,BIRMINGHAM
B25,0,BIRMINGHAM
B26,0,BIRMINGHAM
B27,0,BIRMINGHAM
B28,0,BIRMINGHAM
B29,0,BIRMINGHAM
B30,0,BIRMINGHAM
B31,0,BIRMINGHAM
B32,0,BIRMINGHAM
B33,0,BIRMINGHAM
B34,0,BIRMINGHAM
B35,0,BIRMINGHAM
B36,0,BIRMINGHAM
B37,0,BIRMINGHAM
B38,0,BIRMINGHAM
B40,0,BIRMINGHAM
B42,0,BIRMINGHAM
B43,0,BIRMINGHAM
B44,0,BIRMINGHAM
B45,0,BIRMINGHAM
B46,0,BIRMINGHAM
B47,0,BIRMINGHAM
B48,0,BIRMINGHAM
B49,0,ALCESTER
B50,0,ALCESTER
B60,0,BROMSGROVE
B61,0,BROMSGROVE
B62,0,HALESOWEN
B63,0,HALESOWEN
B64,0,CRADLEY HEATH
B65,0,ROWLEY REGIS
B66,0,SMETHWICK
B67,0,SMETHWICK
B68,0,OLDBURY
B69,0,OLDBURY
B70,0,WEST BROMWICH
B71,0,WEST BROMWICH
B72,0,SUTTON COLDFIELD
B73,0,SUTTON COLDFIELD
B74,0,SUTTON COLDFIELD
B75,0,SUTTON COLDFIELD
B76,0,SUTTON COLDFIELD
B77,0,TAMWORTH
B78,0,TAMWORTH
B79,0,TAMWORTH
B80,0,STUDLEY
B90,0,SOLIHULL
B91,0,SOLIHULL
B92,0,SOLIHULL
B93,0,SOLIHULL
B94,0,SOLIHULL
B95,0,HENLEY-IN-ARDEN
B96,0,REDDITCH
B97,0,REDDITCH
B98,0,REDDITCH
B99,1,BIRMINGHAM
BA1,0,BATH
BA2,0,BATH
BA3,0,RADSTOCK
BA4,0,SHEPTON MALLET
BA5,0,WELLS
BA6,0,GLASTONBURY
BA7,0,CASTLE CARY
BA8,0,TEMPLECOMBE
BA9,0,WINCANTON,BRUTON
BA10,0,BRUTON
BA11,0,FROME
BA12,0,WARMINSTER
BA13,0,WESTBURY
BA14,0,TROWBRIDGE
BA15,0,BRADFORD-ON-AVON
BA16,0,STREET
BA20,0,YEOVIL
BA21,0,YEOVIL
BA22,0,YEOVIL
BB1,0,BLACKBURN
BB2,0,BLACKBURN
BB3,0,DARWEN
BB4,0,ROSSENDALE
BB5,0,ACCRINGTON
BB6,0,BLACKBURN
BB7,0,CLITHEROE
BB8,0,COLNE
BB9,0,NELSON
BB10,0,BURNLEY
BB11,0,BURNLEY
BB12,0,BURNLEY
BB18,0,BARNOLDSWICK
BB94,1,BARNOLDSWICK
BD1,0,BRADFORD
BD2,0,BRADFORD
BD3,0,BRADFORD
BD4,0,BRADFORD
BD5,0,BRADFORD
BD6,0,BRADFORD
BD7,0,BRADFORD
BD8,0,BRADFORD
BD9,0,BRADFORD
BD10,0,BRADFORD
BD11,0,BRADFORD
BD12,0,BRADFORD
BD13,0,BRADFORD
BD14,0,BRADFORD
BD15,0,BRADFORD
BD16,0,BINGLEY
BD17,0,SHIPLEY
BD18,0,SHIPLEY
BD19,0,CLECKHEATON
BD20,0,KEIGHLEY
BD21,0,KEIGHLEY
BD22,0,KEIGHLEY
BD23,0,SKIPTON
BD24,0,SKIPTON,SETTLE
BD97,1,BINGLEY
BD98,1,BRADFORD,SHIPLEY
BD99,1,BRADFORD
BF1,1,BFPO
BH1,0,BOURNEMOUTH
BH2,0,BOURNEMOUTH
BH3,0,BOURNEMOUTH
BH4,0,BOURNEMOUTH
BH5,0,BOURNEMOUTH
BH6,0,BOURNEMOUTH
BH7,0,BOURNEMOUTH
BH8,0,BOURNEMOUTH
BH9,0,BOURNEMOUTH
BH10,0,BOURNEMOUTH
BH11,0,BOURNEMOUTH
BH12,0,POOLE
BH13,0,POOLE
BH14,0,POOLE
BH15,0,POOLE
BH16,0,POOLE
BH17,0,POOLE
BH18,0,BROADSTONE
BH19,0,SWANAGE
BH20,0,WAREHAM
BH21,0,WIMBORNE
BH22,0,FERNDOWN
BH23,0,CHRISTCHURCH
BH24,0,RINGWOOD
BH25,0,NEW MILTON
BH31,0,VERWOOD
BL0,0,BURY
BL1,0,BOLTON
BL2,0,BOLTON
BL3,0,BOLTON
BL4,0,BOLTON
BL5,0,BOLTON
BL6,0,BOLTON
BL7,0,BOLTON
BL8,0,BURY
BL9,0,BURY
BL11,1,BOLTON
BL78,1,BOLTON
BN1,0,BRIGHTON
BN2,0,BRIGHTON
BN3,0,HOVE
BN5,0,HENFIELD
BN6,0,HASSOCKS
BN7,0,LEWES
BN8,0,LEWES
BN9,0,NEWHAVEN
BN10,0,PEACEHAVEN
BN11,0,WORTHING
BN12,0,WORTHING
BN13,0,WORTHING
BN14,0,WORTHING
BN15,0,LANCING
BN16,0,LITTLEHAMPTON
BN17,0,LITTLEHAMPTON
BN18,0,ARUNDEL
BN20,0,EASTBOURNE
BN21,0,EASTBOURNE
BN22,0,EASTBOURNE
BN23,0,EASTBOURNE
BN24,0,PEVENSEY
BN25,0,SEAFORD
BN26,0,POLEGATE
BN27,0,HAILSHAM
BN41,0,BRIGHTON
BN42,0,BRIGHTON
BN43,0,SHOREHAM-BY-SEA
BN44,0,STEYNING
BN45,0,BRIGHTON
BN50,1,BRIGHTON
BN51,1,BRIGHTON
BN52,1,HOVE
BN88,1,BRIGHTON
BN91,1,WORTHING
BN99,1,WORTHING,LANCING
BR1,0,BROMLEY
BR2,0,BROMLEY,KESTON
BR3,0,BECKENHAM
BR4,0,WEST WICKHAM
BR5,0,ORPINGTON
BR6,0,ORPINGTON
BR7,0,CHISLEHURST
BR8,0,SWANLEY
BS0,1,BRISTOL
BS1,0,BRISTOL
BS2,0,BRISTOL
BS3,0,BRISTOL
BS4,0,BRISTOL
BS5,0,BRISTOL
BS6,0,BRISTOL
BS7,0,BRISTOL
BS8,0,BRISTOL
BS9,0,BRISTOL
BS10,0,BRISTOL
BS11,0,BRISTOL
BS13,0,BRISTOL
BS14,0,BRISTOL
BS15,0,BRISTOL
BS16,0,BRISTOL
BS20,0,BRISTOL
BS21,0,CLEVEDON
BS22,0,WESTON-SUPER-MARE
BS23,0,WESTON-SUPER-MARE
BS24,0,WESTON-SUPER-MARE
BS25,0,WINSCOMBE
BS26,0,AXBRIDGE
BS27,0,CHEDDAR
BS28,0,WEDMORE
BS29,0,BANWELL
BS30,0,BRISTOL
BS31,0,BRISTOL
BS32,0,BRISTOL
BS34,0,BRISTOL
BS35,0,BRISTOL
BS36,0,BRISTOL
BS37,0,BRISTOL
BS39,0,BRISTOL
BS40,0,BRISTOL
BS41,0,BRISTOL
BS48,0,BRISTOL
BS49,0,BRISTOL
BS80,1,BRISTOL
BS98,1,BRISTOL
BS99,1,BRISTOL
BT1,0,BELFAST
BT2,0,BELFAST
BT3,0,BELFAST
BT4,0,BELFAST
BT5,0,BELFAST
BT6,0,BELFAST
BT7,0,BELFAST
BT8,0,BELFAST
BT9,0,BELFAST
BT10,0,BELFAST
BT11,0,BELFAST
BT12,0,BELFAST
BT13,0,BELFAST
BT14,0,BELFAST
BT15,0,BELFAST
BT16,0,BELFAST
BT17,0,BELFAST
BT18,0,HOLYWOOD
BT19,0,BANGOR
BT20,0,BANGOR
BT21,0,DONAGHADEE
BT22,0,NEWTOWNARDS
BT23,0,NEWTOWNARDS
BT24,0,BALLYNAHINCH
BT25,0,DROMORE
BT26,0,HILLSBOROUGH
BT27,0,LISBURN
BT28,0,LISBURN
BT29,0,BELFAST,CRUMLIN
BT30,0,DOWNPATRICK
BT31,0,CASTLEWELLAN
BT32,0,BANBRIDGE
BT33,0,NEWCASTLE
BT34,0,NEWRY
BT35,0,NEWRY
BT36,0,NEWTOWNABBEY
BT37,0,NEWTOWNABBEY
BT38,0,CARRICKFERGUS
BT39,0,BALLYCLARE
BT40,0,LARNE
BT41,0,ANTRIM
BT42,0,BALLYMENA
BT43,0,BALLYMENA
BT44,0,BALLYMENA
BT45,0,MAGHERAFELT
BT46,0,MAGHERA
BT47,0,LONDONDERRY
BT48,0,LONDONDERRY
BT49,0,LIMAVADY
BT51,0,COLERAINE
BT52,0,COLERAINE
BT53,0,BALLYMONEY
BT54,0,BALLYCASTLE
BT55,0,PORTSTEWART
BT56,0,PORTRUSH
BT57,0,BUSHMILLS
BT58,1,NEWTOWNABBEY
BT60,0,ARMAGH
BT61,0,ARMAGH
BT62,0,CRAIGAVON
BT63,0,CRAIGAVON
BT64,0,CRAIGAVON
BT65,0,CRAIGAVON
BT66,0,CRAIGAVON
BT67,0,CRAIGAVON
BT68,0,CALEDON
BT69,0,AUGHNACLOY
BT70,0,DUNGANNON
BT71,0,DUNGANNON
BT74,0,ENNISKILLEN
BT75,0,FIVEMILETOWN
BT76,0,CLOGHER
BT77,0,AUGHER
BT78,0,OMAGH
BT79,0,OMAGH
BT80,0,COOKSTOWN
BT81,0,CASTLEDERG
BT82,0,STRABANE
BT92,0,ENNISKILLEN
BT93,0,ENNISKILLEN
BT94,0,ENNISKILLEN
CA1,0,CARLISLE
CA2,0,CARLISLE
CA3,0,CARLISLE
CA4,0,CARLISLE
CA5,0,CARLISLE
CA6,0,CARLISLE
CA7,0,WIGTON
CA8,0,BRAMPTON
CA9,0,ALSTON
CA10,0,PENRITH
CA11,0,PENRITH
CA12,0,KESWICK
CA13,0,COCKERMOUTH
CA14,0,WORKINGTON
CA15,0,MARYPORT
CA16,0,APPLEBY-IN-WESTMORLAND
CA17,0,KIRKBY STEPHEN
CA18,0,RAVENGLASS
CA19,0,HOLMROOK
CA20,0,SEASCALE
CA21,0,BECKERMET
CA22,0,EGREMONT
CA23,0,CLEATOR
CA24,0,MOOR ROW
CA25,0,CLEATOR MOOR
CA26,0,FRIZINGTON
CA27,0,ST. BEES
CA28,0,WHITEHAVEN
CA95,1,WORKINGTON
CA99,1,CARLISLE
CB1,0,CAMBRIDGE
CB2,0,CAMBRIDGE
CB3,0,CAMBRIDGE
CB4,0,CAMBRIDGE
CB5,0,CAMBRIDGE
CB6,0,ELY
CB7,0,ELY
CB8,0,NEWMARKET
CB9,0,HAVERHILL
CB10,0,SAFFRON WALDEN
CB11,0,SAFFRON WALDEN
CB21,0,CAMBRIDGE
CB22,0,CAMBRIDGE
CB23,0,CAMBRIDGE
CB24,0,CAMBRIDGE
CB25,0,CAMBRIDGE
CF3,0,CARDIFF
CF5,0,CARDIFF
CF10,0,CARDIFF
CF11,0,CARDIFF
CF14,0,CARDIFF
CF15,0,CARDIFF
CF23,0,CARDIFF
CF24,0,CARDIFF
CF30,1,CARDIFF
CF31,0,BRIDGEND
CF32,0,BRIDGEND
CF33,0,BRIDGEND
CF34,0,MAESTEG
CF35,0,BRIDGEND
CF36,0,PORTHCAWL
CF37,0,PONTYPRIDD
CF38,0,PONTYPRIDD
CF39,0,PORTH
CF40,0,TONYPANDY
CF41,0,PENTRE
CF42,0,TREORCHY
CF43,0,FERNDALE
CF44,0,ABERDARE
CF45,0,MOUNTAIN ASH
CF46,0,TREHARRIS
CF47,0,MERTHYR TYDFIL
CF48,0,MERTHYR TYDFIL
CF61,0,LLANTWIT MAJOR
CF62,0,BARRY
CF63,0,BARRY
CF64,0,DINAS POWYS,PENARTH
CF71,0,LLANTWIT MAJOR,COWBRIDGE
CF72,0,PONTYCLUN
CF81,0,BARGOED
CF82,0,HENGOED
CF83,0,CAERPHILLY
CF91,1,CARDIFF
CF95,1,CARDIFF
CF99,1,CARDIFF
CH1,0,CHESTER
CH2,0,CHESTER
CH3,0,CHESTER
CH4,0,CHESTER
CH5,0,DEESIDE
CH6,0,BAGILLT,FLINT
CH7,0,BUCKLEY,MOLD
CH8,0,HOLYWELL
CH25,1,BIRKENHEAD
CH26,1,PRENTON
CH27,1,WALLASEY
CH28,1,WIRRAL
CH29,1,WIRRAL
CH30,1,WIRRAL
CH31,1,WIRRAL
CH32,1,WIRRAL
CH33,1,NESTON
CH34,1,ELLESMERE PORT
CH41,0,BIRKENHEAD
CH42,0,BIRKENHEAD
CH43,0,PRENTON
CH44,0,WALLASEY
CH45,0,WALLASEY
CH46,0,WIRRAL
CH47,0,WIRRAL
CH48,0,WIRRAL
CH49,0,WIRRAL
CH60,0,WIRRAL
CH61,0,WIRRAL
CH62,0,WIRRAL
CH63,0,WIRRAL
CH64,0,NESTON
CH65,0,ELLESMERE PORT
CH66,0,ELLESMERE PORT
CH70,1,CHESTER
CH88,1,CHESTER
CH99,1,CHESTER
CM0,0,BURNHAM-ON-CROUCH,SOUTHMINSTER
CM1,0,CHELMSFORD
CM2,0,CHELMSFORD
CM3,0,CHELMSFORD
CM4,0,INGATESTONE
CM5,0,ONGAR
CM6,0,DUNMOW
CM7,1,DUNMOW,BRAINTREE
CM8,0,WITHAM
CM9,0,MALDON
CM11,0,BILLERICAY
CM12,0,BILLERICAY
CM13,0,BRENTWOOD
CM14,0,BRENTWOOD
CM15,0,BRENTWOOD
CM16,0,EPPING
CM17,0,HARLOW
CM18,0,HARLOW
CM19,0,HARLOW
CM20,0,HARLOW
CM21,0,SAWBRIDGEWORTH
CM22,0,BISHOP'S STORTFORD
CM23,0,BISHOP'S STORTFORD
CM24,0,STANSTED
CM77,0,BRAINTREE
CM92,1,CHELMSFORD
CM98,1,CHELMSFORD
CM99,1,CHELMSFORD
CO1,0,COLCHESTER
CO2,0,COLCHESTER
CO3,0,COLCHESTER
CO4,0,COLCHESTER
CO5,0,COLCHESTER
CO6,0,COLCHESTER
CO7,0,COLCHESTER
CO8,0,BURES
CO9,0,HALSTEAD
CO10,0,SUDBURY
CO11,0,MANNINGTREE
CO12,0,HARWICH
CO13,0,FRINTON-ON-SEA
CO14,0,WALTON ON THE NAZE
CO15,0,CLACTON-ON-SEA
CO16,0,CLACTON-ON-SEA
CR0,0,CROYDON
CR2,0,SOUTH CROYDON
CR3,0,CATERHAM,WHYTELEAFE
CR4,0,MITCHAM
CR5,0,COULSDON
CR6,0,WARLINGHAM
CR7,0,THORNTON HEATH
CR8,0,KENLEY,PURLEY
CR9,1,CROYDON
CR44,1,CROYDON
CR90,1,CROYDON
CT1,0,CANTERBURY
CT2,0,CANTERBURY
CT3,0,CANTERBURY
CT4,0,CANTERBURY
CT5,0,WHITSTABLE
CT6,0,HERNE BAY
CT7,0,BIRCHINGTON
CT8,0,WESTGATE-ON-SEA
CT9,1,BIRCHINGTON,MARGATE
CT10,0,BROADSTAIRS
CT11,0,RAMSGATE
CT12,0,RAMSGATE
CT13,0,SANDWICH
CT14,0,DEAL
CT15,0,DOVER
CT16,0,DOVER
CT17,0,DOVER
CT18,0,FOLKESTONE
CT19,0,FOLKESTONE
CT20,0,FOLKESTONE
CT21,0,HYTHE
CT50,1,FOLKESTONE
CV1,0,COVENTRY
CV2,0,COVENTRY
CV3,0,COVENTRY
CV4,0,COVENTRY
CV5,0,COVENTRY
CV6,0,COVENTRY
CV7,0,COVENTRY
CV8,0,COVENTRY,KENILWORTH
CV9,0,ATHERSTONE
CV10,0,NUNEATON
CV11,0,NUNEATON
CV12,0,BEDWORTH
CV13,0,NUNEATON
CV21,0,RUGBY
CV22,0,RUGBY
CV23,0,RUGBY
CV31,0,LEAMINGTON SPA
CV32,0,LEAMINGTON SPA
CV33,0,LEAMINGTON SPA
CV34,0,WARWICK
CV35,0,WARWICK
CV36,0,SHIPSTON-ON-STOUR
CV37,0,SHIPSTON-ON-STOUR,STRATFORD-UPON-AVON
CV47,0,SOUTHAM
CW1,0,CREWE
CW2,0,CREWE
CW3,0,CREWE
CW4,0,CREWE
CW5,0,NANTWICH
CW6,0,TARPORLEY
CW7,0,WINSFORD
CW8,0,NORTHWICH
CW9,0,NORTHWICH
CW10,0,MIDDLEWICH
CW11,0,SANDBACH
CW12,0,CONGLETON
CW98,1,CREWE
DA1,0,DARTFORD
DA2,0,DARTFORD
DA3,0,LONGFIELD
DA4,0,DARTFORD
DA5,0,BEXLEY
DA6,0,BEXLEYHEATH
DA7,0,BEXLEYHEATH,WELLING
DA8,0,ERITH
DA9,0,GREENHITHE
DA10,0,DARTFORD,SWANSCOMBE
DA11,0,GRAVESEND
DA12,0,GRAVESEND
DA13,0,GRAVESEND
DA14,0,SIDCUP
DA15,0,SIDCUP
DA16,0,WELLING
DA17,0,BELVEDERE
DA18,0,ERITH
DD1,0,DUNDEE
DD2,0,DUNDEE
DD3,0,DUNDEE
DD4,0,DUNDEE
DD5,0,DUNDEE
DD6,0,NEWPORT-ON-TAY,TAYPORT
DD7,0,CARNOUSTIE
DD8,0,FORFAR,KIRRIEMUIR
DD9,0,BRECHIN
DD10,0,MONTROSE
DD11,0,ARBROATH
DE1,0,DERBY
DE3,0,DERBY
DE4,0,MATLOCK
DE5,0,RIPLEY
DE6,0,ASHBOURNE
DE7,0,ILKESTON
DE11,0,SWADLINCOTE
DE12,0,SWADLINCOTE
DE13,0,BURTON-ON-TRENT
DE14,0,BURTON-ON-TRENT
DE15,0,BURTON-ON-TRENT
DE21,0,DERBY
DE22,0,DERBY
DE23,0,DERBY
DE24,0,DERBY
DE45,0,BAKEWELL
DE55,0,ALFRETON
DE56,0,BELPER
DE65,0,DERBY
DE72,0,DERBY
DE73,0,DERBY
DE74,0,DERBY
DE75,0,HEANOR
DE99,1,DERBY
DG1,0,DUMFRIES
DG2,0,DUMFRIES
DG3,0,THORNHILL
DG4,0,SANQUHAR
DG5,0,DALBEATTIE
DG6,0,KIRKCUDBRIGHT
DG7,0,CASTLE DOUGLAS
DG8,0,NEWTON STEWART
DG9,0,STRANRAER
DG10,0,MOFFAT
DG11,0,LOCKERBIE
DG12,0,ANNAN
DG13,0,LANGHOLM
DG14,0,CANONBIE
DG16,0,GRETNA
DH1,0,DURHAM
DH2,0,CHESTER LE STREET
DH3,0,CHESTER LE STREET
DH4,0,HOUGHTON LE SPRING
DH5,0,HOUGHTON LE SPRING
DH6,0,DURHAM
DH7,0,DURHAM
DH8,0,DURHAM,CONSETT,STANLEY
DH9,0,STANLEY
DH97,1,DURHAM
DH98,1,DURHAM
DH99,1,DURHAM
DL1,0,DARLINGTON
DL2,0,DARLINGTON
DL3,0,DARLINGTON
DL4,0,SHILDON
DL5,0,NEWTON AYCLIFFE
DL6,0,NORTHALLERTON
DL7,0,NORTHALLERTON
DL8,0,BEDALE,HAWES,LEYBURN
DL9,0,CATTERICK GARRISON
DL10,0,RICHMOND
DL11,0,RICHMOND
DL12,0,BARNARD CASTLE
DL13,0,BISHOP AUCKLAND
DL14,0,BISHOP AUCKLAND
DL15,0,CROOK
DL16,0,SPENNYMOOR,FERRYHILL
DL17,0,FERRYHILL
DL98,1,DARLINGTON
DN1,0,DONCASTER
DN2,0,DONCASTER
DN3,0,DONCASTER
DN4,0,DONCASTER
DN5,0,DONCASTER
DN6,0,DONCASTER
DN7,0,DONCASTER
DN8,0,DONCASTER
DN9,0,DONCASTER
DN10,0,DONCASTER
DN11,0,DONCASTER
DN12,0,DONCASTER
DN14,0,GOOLE
DN15,0,SCUNTHORPE
DN16,0,SCUNTHORPE
DN17,0,SCUNTHORPE
DN18,0,BARTON-UPON-HUMBER
DN19,0,BARROW-UPON-HUMBER
DN20,0,BRIGG
DN21,0,GAINSBOROUGH
DN22,0,RETFORD
DN31,0,GRIMSBY
DN32,0,GRIMSBY
DN33,0,GRIMSBY
DN34,0,GRIMSBY
DN35,0,CLEETHORPES
DN36,0,GRIMSBY
DN37,0,GRIMSBY
DN38,0,BARNETBY
DN39,0,ULCEBY
DN40,0,IMMINGHAM
DN41,0,GRIMSBY
DN55,1,DONCASTER
DT1,0,DORCHESTER
DT2,0,DORCHESTER
DT3,0,WEYMOUTH
DT4,0,WEYMOUTH
DT5,0,PORTLAND
DT6,0,BRIDPORT
DT7,0,LYME REGIS
DT8,0,BEAMINSTER
DT9,0,SHERBORNE
DT10,0,STURMINSTER NEWTON
DT11,0,BLANDFORD FORUM
DY1,0,DUDLEY
DY2,0,DUDLEY
DY3,0,DUDLEY
DY4,0,TIPTON
DY5,0,BRIERLEY HILL
DY6,0,KINGSWINFORD
DY7,0,STOURBRIDGE
DY8,0,STOURBRIDGE
DY9,0,STOURBRIDGE
DY10,0,KIDDERMINSTER
DY11,0,KIDDERMINSTER
DY12,0,BEWDLEY
DY13,0,STOURPORT-ON-SEVERN
DY14,0,KIDDERMINSTER
E1W,0,LONDON
E1,0,LONDON
E2,0,LONDON
E3,0,LONDON
E4,0,LONDON
E5,0,LONDON
E6,0,LONDON
E7,0,LONDON
E8,0,LONDON
E9,0,LONDON
E10,0,LONDON
E11,0,LONDON
E12,0,LONDON
E13,0,LONDON
E14,0,LONDON
E15,0,LONDON
E16,0,LONDON
E17,0,LONDON
E18,0,LONDON
E20,1,LONDON
E77,1,LONDON
E98,1,LONDON
EC1N,0,LONDON
EC1V,0,LONDON
EC1A,0,LONDON
EC1M,0,LONDON
EC1P,1,LONDON
EC1R,0,LONDON
EC1Y,0,LONDON
EC2R,0,LONDON
EC2N,0,LONDON
EC2A,0,LONDON
EC2M,0,LONDON
EC2V,0,LONDON
EC2P,1,LONDON
EC2Y,0,LONDON
EC3M,0,LONDON
EC3V,0,LONDON
EC3N,0,LONDON
EC3P,1,LONDON
EC3A,0,LONDON
EC3R,0,LONDON
EC4A,0,LONDON
EC4P,1,LONDON
EC4R,0,LONDON
EC4Y,0,LONDON
EC4N,0,LONDON
EC4V,0,LONDON
EC4M,0,LONDON
EC50,1,LONDON
EH1,0,EDINBURGH
EH2,0,EDINBURGH
EH3,0,EDINBURGH
EH4,0,EDINBURGH
EH5,0,EDINBURGH
EH6,0,EDINBURGH
EH7,0,EDINBURGH
EH8,0,EDINBURGH
EH9,0,EDINBURGH
EH10,0,EDINBURGH
EH11,0,EDINBURGH
EH12,0,EDINBURGH
EH13,0,EDINBURGH
EH14,0,EDINBURGH,BALERNO,CURRIE,JUNIPER GREEN
EH15,0,EDINBURGH
EH16,0,EDINBURGH
EH17,0,EDINBURGH
EH18,0,LASSWADE
EH19,0,BONNYRIGG
EH20,0,LOANHEAD
EH21,0,MUSSELBURGH
EH22,0,DALKEITH
EH23,0,GOREBRIDGE
EH24,0,ROSEWELL
EH25,0,ROSLIN
EH26,0,PENICUIK
EH27,0,KIRKNEWTON
EH28,0,NEWBRIDGE
EH29,0,KIRKLISTON
EH30,0,SOUTH QUEENSFERRY
EH31,0,GULLANE
EH32,0,LONGNIDDRY,PRESTONPANS
EH33,0,TRANENT
EH34,0,TRANENT
EH35,0,TRANENT
EH36,0,HUMBIE
EH37,0,PATHHEAD
EH38,0,HERIOT
EH39,0,NORTH BERWICK
EH40,0,EAST LINTON
EH41,0,HADDINGTON
EH42,0,DUNBAR
EH43,0,WALKERBURN
EH44,0,INNERLEITHEN
EH45,0,PEEBLES
EH46,0,WEST LINTON
EH47,0,BATHGATE
EH48,0,BATHGATE
EH49,0,LINLITHGOW
EH51,0,BO'NESS
EH52,0,BROXBURN
EH53,0,LIVINGSTON
EH54,0,LIVINGSTON
EH55,0,WEST CALDER
EH91,1,EDINBURGH
EH95,1,EDINBURGH
EH99,1,EDINBURGH
EN1,0,ENFIELD
EN2,0,ENFIELD
EN3,0,ENFIELD
EN4,0,BARNET
EN5,0,BARNET
EN6,0,POTTERS BAR
EN7,0,WALTHAM CROSS
EN8,0,WALTHAM CROSS
EN9,0,WALTHAM ABBEY
EN10,0,BROXBOURNE
EN11,1,BROXBOURNE,HODDESDON
EN77,1,WALTHAM CROSS
EX1,0,EXETER
EX2,0,EXETER
EX3,0,EXETER
EX4,0,EXETER
EX5,0,EXETER
EX6,0,EXETER
EX7,0,DAWLISH
EX8,0,EXMOUTH
EX9,0,BUDLEIGH SALTERTON
EX10,0,SIDMOUTH
EX11,0,OTTERY ST. MARY
EX12,0,SEATON
EX13,0,AXMINSTER
EX14,0,HONITON
EX15,0,CULLOMPTON
EX16,0,TIVERTON
EX17,0,CREDITON
EX18,0,CHULMLEIGH
EX19,0,WINKLEIGH
EX20,0,NORTH TAWTON,OKEHAMPTON
EX21,0,BEAWORTHY
EX22,0,HOLSWORTHY
EX23,0,BUDE
EX24,0,COLYTON
EX31,0,BARNSTAPLE
EX32,0,BARNSTAPLE
EX33,0,BRAUNTON
EX34,0,ILFRACOMBE,WOOLACOMBE
EX35,0,LYNMOUTH,LYNTON
EX36,0,SOUTH MOLTON
EX37,0,UMBERLEIGH
EX38,0,TORRINGTON
EX39,0,BIDEFORD
FK1,0,FALKIRK
FK2,0,FALKIRK
FK3,0,GRANGEMOUTH
FK4,0,BONNYBRIDGE
FK5,0,LARBERT
FK6,0,DENNY
FK7,0,STIRLING
FK8,0,STIRLING
FK9,0,STIRLING
FK10,0,ALLOA,CLACKMANNAN
FK11,0,MENSTRIE
FK12,0,ALVA
FK13,0,TILLICOULTRY
FK14,0,DOLLAR
FK15,0,DUNBLANE
FK16,0,DOUNE
FK17,0,CALLANDER
FK18,0,CALLANDER
FK19,0,LOCHEARNHEAD
FK20,0,CRIANLARICH
FK21,0,KILLIN
FY0,1,BLACKPOOL
FY1,0,BLACKPOOL
FY2,0,BLACKPOOL
FY3,0,BLACKPOOL
FY4,0,BLACKPOOL
FY5,0,THORNTON-CLEVELEYS
FY6,0,POULTON-LE-FYLDE
FY7,0,FLEETWOOD
FY8,0,LYTHAM ST. ANNES
G1,0,GLASGOW
G2,0,GLASGOW
G3,0,GLASGOW
G4,0,GLASGOW
G5,0,GLASGOW
G9,1,GLASGOW
G11,0,GLASGOW
G12,0,GLASGOW
G13,0,GLASGOW
G14,0,GLASGOW
G15,0,GLASGOW
G20,0,GLASGOW
G21,0,GLASGOW
G22,0,GLASGOW
G23,0,GLASGOW
G31,0,GLASGOW
G32,0,GLASGOW
G33,0,GLASGOW
G34,0,GLASGOW
G40,0,GLASGOW
G41,0,GLASGOW
G42,0,GLASGOW
G43,0,GLASGOW
G44,0,GLASGOW
G45,0,GLASGOW
G46,0,GLASGOW
G51,0,GLASGOW
G52,0,GLASGOW
G53,0,GLASGOW
G58,1,GLASGOW
G60,0,GLASGOW
G61,0,GLASGOW
G62,0,GLASGOW
G63,0,GLASGOW
G64,0,GLASGOW
G65,0,GLASGOW
G66,0,GLASGOW
G67,0,GLASGOW
G68,0,GLASGOW
G69,0,GLASGOW
G70,1,GLASGOW
G71,0,GLASGOW
G72,0,GLASGOW
G73,0,GLASGOW
G74,0,GLASGOW
G75,0,GLASGOW
G76,0,GLASGOW
G77,0,GLASGOW
G78,0,GLASGOW
G79,1,GLASGOW
G81,0,CLYDEBANK
G82,0,DUMBARTON
G83,0,ALEXANDRIA,ARROCHAR
G84,0,HELENSBURGH
G90,1,GLASGOW
GL1,0,GLOUCESTER
GL2,0,GLOUCESTER
GL3,0,GLOUCESTER
GL4,0,GLOUCESTER
GL5,0,STROUD
GL6,0,STROUD
GL7,0,CIRENCESTER,FAIRFORD,LECHLADE
GL8,0,TETBURY
GL9,0,BADMINTON
GL10,0,STONEHOUSE
GL11,0,DURSLEY,WOTTON-UNDER-EDGE
GL12,0,WOTTON-UNDER-EDGE
GL13,0,BERKELEY
GL14,0,CINDERFORD,NEWNHAM,WESTBURY-ON-SEVERN
GL15,0,BLAKENEY,LYDNEY
GL16,0,COLEFORD
GL17,0,DRYBROOK,LONGHOPE,LYDBROOK,MITCHELDEAN,RUARDEAN
GL18,0,DYMOCK,NEWENT
GL19,0,GLOUCESTER
GL20,0,TEWKESBURY
GL50,0,CHELTENHAM
GL51,0,CHELTENHAM
GL52,0,CHELTENHAM
GL53,0,CHELTENHAM
GL54,0,CHELTENHAM
GL55,0,CHIPPING CAMPDEN
GL56,0,MORETON-IN-MARSH
GU1,0,GUILDFORD
GU2,0,GUILDFORD
GU3,0,GUILDFORD
GU4,0,GUILDFORD
GU5,0,GUILDFORD
GU6,0,CRANLEIGH
GU7,0,GODALMING
GU8,0,GODALMING
GU9,0,FARNHAM
GU10,0,FARNHAM
GU11,0,ALDERSHOT
GU12,0,ALDERSHOT
GU14,0,FARNBOROUGH
GU15,0,CAMBERLEY
GU16,0,CAMBERLEY
GU17,0,CAMBERLEY
GU18,0,LIGHTWATER
GU19,0,BAGSHOT
GU20,0,WINDLESHAM
GU21,0,WOKING
GU22,0,WOKING
GU23,0,WOKING
GU24,0,WOKING
GU25,0,VIRGINIA WATER
GU26,0,HINDHEAD
GU27,1,HINDHEAD,HASLEMERE
GU28,0,PETWORTH
GU29,0,MIDHURST
GU30,0,LIPHOOK
GU31,0,PETERSFIELD
GU32,0,PETERSFIELD
GU33,0,LISS
GU34,0,ALTON
GU35,0,BORDON
GU46,0,YATELEY
GU47,0,SANDHURST
GU51,0,FLEET
GU52,0,FLEET
GU95,1,CAMBERLEY
GY1,0,GUERNSEY
GY2,0,GUERNSEY
GY3,0,GUERNSEY
GY4,0,GUERNSEY
GY5,0,GUERNSEY
GY6,0,GUERNSEY
GY7,0,GUERNSEY
GY8,0,GUERNSEY
GY9,0,GUERNSEY
GY10,0,GUERNSEY
HA0,0,WEMBLEY
HA1,0,HARROW
HA2,0,HARROW
HA3,0,HARROW
HA4,0,RUISLIP
HA5,0,PINNER
HA6,0,NORTHWOOD
HA7,0,STANMORE
HA8,0,EDGWARE
HA9,0,WEMBLEY
HD1,0,HUDDERSFIELD
HD2,0,HUDDERSFIELD
HD3,0,HUDDERSFIELD
HD4,0,HUDDERSFIELD
HD5,0,HUDDERSFIELD
HD6,0,BRIGHOUSE
HD7,0,HUDDERSFIELD
HD8,0,HUDDERSFIELD
HD9,0,HOLMFIRTH
HG1,0,HARROGATE
HG2,0,HARROGATE
HG3,0,HARROGATE
HG4,0,RIPON
HG5,0,KNARESBOROUGH
HP1,0,HEMEL HEMPSTEAD
HP2,0,HEMEL HEMPSTEAD
HP3,0,HEMEL HEMPSTEAD
HP4,0,BERKHAMSTED
HP5,0,CHESHAM
HP6,0,AMERSHAM
HP7,0,AMERSHAM
HP8,0,CHALFONT ST. GILES
HP9,0,BEACONSFIELD
HP10,0,HIGH WYCOMBE
HP11,0,HIGH WYCOMBE
HP12,0,HIGH WYCOMBE
HP13,0,HIGH WYCOMBE
HP14,0,HIGH WYCOMBE
HP15,0,HIGH WYCOMBE
HP16,0,GREAT MISSENDEN
HP17,0,AYLESBURY
HP18,0,AYLESBURY
HP19,0,AYLESBURY
HP20,0,AYLESBURY
HP21,0,AYLESBURY
HP22,0,AYLESBURY,PRINCES RISBOROUGH
HP23,0,TRING
HP27,0,PRINCES RISBOROUGH
HR1,0,HEREFORD
HR2,0,HEREFORD
HR3,0,HEREFORD
HR4,0,HEREFORD
HR5,0,KINGTON
HR6,0,LEOMINSTER
HR7,0,BROMYARD
HR8,0,LEDBURY
HR9,0,ROSS-ON-WYE
HS1,0,STORNOWAY
HS2,0,ISLE OF LEWIS
HS3,0,ISLE OF HARRIS
HS4,0,ISLE OF SCALPAY
HS5,0,ISLE OF HARRIS
HS6,0,ISLE OF NORTH UIST
HS7,0,ISLE OF BENBECULA
HS8,0,ISLE OF SOUTH UIST
HS9,0,ISLE OF BARRA
HU1,0,HULL
HU2,0,HULL
HU3,0,HULL
HU4,0,HULL
HU5,0,HULL
HU6,0,HULL
HU7,0,HULL
HU8,0,HULL
HU9,0,HULL
HU10,0,HULL
HU11,0,HULL
HU12,0,HULL
HU13,0,HESSLE
HU14,0,NORTH FERRIBY
HU15,0,BROUGH
HU16,0,COTTINGHAM
HU17,0,BEVERLEY
HU18,0,HORNSEA
HU19,0,WITHERNSEA
HU20,0,COTTINGHAM
HX1,0,HALIFAX,ELLAND
HX2,0,HALIFAX
HX3,0,HALIFAX
HX4,0,HALIFAX
HX5,0,ELLAND
HX6,0,SOWERBY BRIDGE
HX7,0,HEBDEN BRIDGE
IG1,0,ILFORD
IG2,0,ILFORD
IG3,0,ILFORD
IG4,0,ILFORD
IG5,0,ILFORD
IG6,0,ILFORD
IG7,0,CHIGWELL
IG8,1,CHIGWELL,WOODFORD GREEN
IG9,0,BUCKHURST HILL
IG10,0,LOUGHTON
IG11,0,BARKING
IM1,0,ISLE OF MAN
IM2,0,ISLE OF MAN
IM3,0,ISLE OF MAN
IM4,0,ISLE OF MAN
IM5,0,ISLE OF MAN
IM6,0,ISLE OF MAN
IM7,0,ISLE OF MAN
IM8,0,ISLE OF MAN
IM9,0,ISLE OF MAN
IM99,1,ISLE OF MAN
IP1,0,IPSWICH
IP2,0,IPSWICH
IP3,0,IPSWICH
IP4,0,IPSWICH
IP5,0,IPSWICH
IP6,0,IPSWICH
IP7,0,IPSWICH
IP8,0,IPSWICH
IP9,0,IPSWICH
IP10,0,IPSWICH
IP11,0,FELIXSTOWE
IP12,0,WOODBRIDGE
IP13,0,WOODBRIDGE
IP14,0,STOWMARKET
IP15,0,ALDEBURGH
IP16,0,LEISTON
IP17,0,SAXMUNDHAM
IP18,0,SOUTHWOLD
IP19,0,HALESWORTH
IP20,0,HARLESTON
IP21,0,DISS,EYE
IP22,0,DISS
IP23,0,EYE
IP24,0,THETFORD
IP25,0,THETFORD
IP26,0,THETFORD
IP27,0,BRANDON
IP28,0,BURY ST. EDMUNDS
IP29,0,BURY ST. EDMUNDS
IP30,0,BURY ST. EDMUNDS
IP31,0,BURY ST. EDMUNDS
IP32,0,BURY ST. EDMUNDS
IP33,0,BURY ST. EDMUNDS
IP98,1,DISS
IV1,0,INVERNESS
IV2,0,INVERNESS
IV3,0,INVERNESS
IV4,0,BEAULY
IV5,0,INVERNESS
IV6,0,MUIR OF ORD
IV7,0,DINGWALL
IV8,0,MUNLOCHY
IV9,0,AVOCH
IV10,0,FORTROSE
IV11,0,CROMARTY
IV12,0,NAIRN
IV13,0,INVERNESS
IV14,0,STRATHPEFFER
IV15,0,DINGWALL
IV16,0,DINGWALL
IV17,0,ALNESS
IV18,0,INVERGORDON
IV19,0,TAIN
IV20,0,TAIN
IV21,0,GAIRLOCH
IV22,0,ACHNASHEEN
IV23,0,GARVE
IV24,0,ARDGAY
IV25,0,DORNOCH
IV26,0,ULLAPOOL
IV27,0,LAIRG
IV28,0,ROGART
IV30,0,ELGIN
IV31,0,LOSSIEMOUTH
IV32,0,FOCHABERS
IV36,0,FORRES
IV40,0,KYLE
IV41,0,ISLE OF SKYE
IV42,0,ISLE OF SKYE
IV43,0,ISLE OF SKYE
IV44,0,ISLE OF SKYE
IV45,0,ISLE OF SKYE
IV46,0,ISLE OF SKYE
IV47,0,ISLE OF SKYE
IV48,0,ISLE OF SKYE
IV49,0,ISLE OF SKYE
IV51,0,PORTREE
IV52,0,PLOCKTON
IV53,0,STROME FERRY
IV54,0,STRATHCARRON
IV55,0,ISLE OF SKYE
IV56,0,ISLE OF SKYE
IV63,0,INVERNESS
IV99,1,INVERNESS
JE1,1,JERSEY
JE2,0,JERSEY
JE3,0,JERSEY
JE4,1,JERSEY
JE5,0,JERSEY
KA1,0,KILMARNOCK
KA2,0,KILMARNOCK
KA3,0,KILMARNOCK
KA4,0,GALSTON
KA5,0,MAUCHLINE
KA6,0,AYR
KA7,0,AYR
KA8,0,AYR
KA9,0,PRESTWICK
KA10,0,TROON
KA11,0,IRVINE
KA12,0,IRVINE
KA13,0,KILWINNING
KA14,0,BEITH
KA15,0,BEITH
KA16,0,NEWMILNS
KA17,0,DARVEL
KA18,0,CUMNOCK
KA19,0,MAYBOLE
KA20,0,STEVENSTON
KA21,0,SALTCOATS
KA22,0,ARDROSSAN
KA23,0,WEST KILBRIDE
KA24,0,DALRY
KA25,0,KILBIRNIE
KA26,0,GIRVAN
KA27,0,ISLE OF ARRAN
KA28,0,ISLE OF CUMBRAE
KA29,0,LARGS
KA30,0,LARGS
KT1,0,KINGSTON UPON THAMES
KT2,0,KINGSTON UPON THAMES
KT3,0,NEW MALDEN
KT4,0,WORCESTER PARK
KT5,0,SURBITON
KT6,0,SURBITON
KT7,0,THAMES DITTON
KT8,0,EAST MOLESEY,WEST MOLESEY
KT9,0,CHESSINGTON
KT10,0,ESHER
KT11,0,COBHAM
KT12,0,WALTON-ON-THAMES
KT13,0,WEYBRIDGE
KT14,0,WEST BYFLEET
KT15,0,ADDLESTONE
KT16,0,CHERTSEY
KT17,0,EPSOM
KT18,0,EPSOM
KT19,0,EPSOM
KT20,0,TADWORTH
KT21,0,ASHTEAD
KT22,0,LEATHERHEAD
KT23,0,LEATHERHEAD
KT24,0,LEATHERHEAD
KW1,0,WICK
KW2,0,LYBSTER
KW3,0,LYBSTER
KW5,0,LATHERON
KW6,0,DUNBEATH
KW7,0,BERRIEDALE
KW8,0,HELMSDALE
KW9,0,BRORA
KW10,0,GOLSPIE
KW11,0,KINBRACE
KW12,0,HALKIRK
KW13,0,FORSINARD
KW14,0,THURSO
KW15,0,KIRKWALL
KW16,0,STROMNESS
KW17,0,ORKNEY
KY1,0,KIRKCALDY
KY2,0,KIRKCALDY
KY3,0,BURNTISLAND
KY4,0,COWDENBEATH,KELTY
KY5,0,LOCHGELLY
KY6,0,GLENROTHES
KY7,0,GLENROTHES
KY8,0,LEVEN
KY9,0,LEVEN
KY10,0,ANSTRUTHER
KY11,0,DUNFERMLINE,INVERKEITHING
KY12,0,DUNFERMLINE
KY13,0,KINROSS
KY14,0,CUPAR
KY15,0,CUPAR
KY16,0,ST. ANDREWS
KY99,1,DUNFERMLINE
L1,0,LIVERPOOL
L2,0,LIVERPOOL
L3,0,LIVERPOOL
L4,0,LIVERPOOL
L5,0,LIVERPOOL
L6,0,LIVERPOOL
L7,0,LIVERPOOL
L8,0,LIVERPOOL
L9,0,LIVERPOOL
L10,0,LIVERPOOL
L11,0,LIVERPOOL
L12,0,LIVERPOOL
L13,0,LIVERPOOL
L14,0,LIVERPOOL
L15,0,LIVERPOOL
L16,0,LIVERPOOL
L17,0,LIVERPOOL
L18,0,LIVERPOOL
L19,0,LIVERPOOL
L20,0,LIVERPOOL,BOOTLE
L21,0,LIVERPOOL
L22,0,LIVERPOOL
L23,0,LIVERPOOL
L24,0,LIVERPOOL
L25,0,LIVERPOOL
L26,0,LIVERPOOL
L27,0,LIVERPOOL
L28,0,LIVERPOOL
L29,0,LIVERPOOL
L30,0,BOOTLE
L31,0,LIVERPOOL
L32,0,LIVERPOOL
L33,0,LIVERPOOL
L34,0,PRESCOT
L35,0,PRESCOT
L36,0,LIVERPOOL
L37,0,LIVERPOOL
L38,0,LIVERPOOL
L39,0,ORMSKIRK
L40,0,ORMSKIRK
L67,1,LIVERPOOL
L68,1,LIVERPOOL
L69,1,LIVERPOOL,BOOTLE
L70,1,LIVERPOOL
L71,1,LIVERPOOL
L72,1,LIVERPOOL
L73,1,LIVERPOOL
L74,1,LIVERPOOL
L75,1,LIVERPOOL
L80,1,BOOTLE
LA1,0,LANCASTER
LA2,0,LANCASTER
LA3,0,MORECAMBE
LA4,0,MORECAMBE
LA5,0,CARNFORTH
LA6,0,CARNFORTH
LA7,0,MILNTHORPE
LA8,0,KENDAL
LA9,0,KENDAL
LA10,0,SEDBERGH
LA11,0,GRANGE-OVER-SANDS
LA12,0,ULVERSTON
LA13,0,BARROW-IN-FURNESS
LA14,0,BARROW-IN-FURNESS,DALTON-IN-FURNESS
LA15,0,DALTON-IN-FURNESS
LA16,0,ASKAM-IN-FURNESS
LA17,0,KIRKBY-IN-FURNESS
LA18,0,MILLOM
LA19,0,MILLOM
LA20,0,BROUGHTON-IN-FURNESS
LA21,0,CONISTON
LA22,0,AMBLESIDE
LA23,0,WINDERMERE
LD1,0,LLANDRINDOD WELLS
LD2,0,BUILTH WELLS
LD3,0,BRECON
LD4,0,LLANGAMMARCH WELLS
LD5,0,LLANWRTYD WELLS
LD6,0,RHAYADER
LD7,0,KNIGHTON
LD8,0,PRESTEIGNE
LE1,0,LEICESTER
LE2,0,LEICESTER
LE3,0,LEICESTER
LE4,0,LEICESTER
LE5,0,LEICESTER
LE6,0,LEICESTER
LE7,0,LEICESTER
LE8,0,LEICESTER
LE9,0,LEICESTER
LE10,0,HINCKLEY
LE11,0,LOUGHBOROUGH
LE12,0,LOUGHBOROUGH
LE13,0,MELTON MOWBRAY
LE14,0,MELTON MOWBRAY
LE15,0,OAKHAM
LE16,0,MARKET HARBOROUGH
LE17,0,LUTTERWORTH
LE18,0,WIGSTON
LE19,0,LEICESTER
LE21,1,LEICESTER
LE41,1,LEICESTER
LE55,1,LEICESTER
LE65,0,ASHBY-DE-LA-ZOUCH
LE67,0,COALVILLE,IBSTOCK,MARKFIELD
LE87,1,LEICESTER
LE94,1,LEICESTER
LE95,1,LEICESTER
LL11,0,WREXHAM
LL12,0,WREXHAM
LL13,0,WREXHAM
LL14,0,WREXHAM
LL15,0,RUTHIN
LL16,0,DENBIGH
LL17,0,ST. ASAPH
LL18,1,ST. ASAPH,RHYL
LL19,0,PRESTATYN
LL20,0,LLANGOLLEN
LL21,0,CORWEN
LL22,0,ABERGELE
LL23,0,BALA
LL24,0,BETWS-Y-COED
LL25,0,DOLWYDDELAN
LL26,0,LLANRWST
LL27,0,TREFRIW
LL28,0,COLWYN BAY
LL29,0,COLWYN BAY
LL30,0,LLANDUDNO
LL31,0,CONWY,LLANDUDNO JUNCTION
LL32,0,CONWY
LL33,0,LLANFAIRFECHAN
LL34,0,PENMAENMAWR
LL35,0,ABERDOVEY
LL36,0,TYWYN
LL37,0,LLWYNGWRIL
LL38,0,FAIRBOURNE
LL39,0,ARTHOG
LL40,0,DOLGELLAU
LL41,0,BLAENAU FFESTINIOG
LL42,0,BARMOUTH
LL43,0,TALYBONT
LL44,0,DYFFRYN ARDUDWY
LL45,0,LLANBEDR
LL46,0,HARLECH
LL47,0,TALSARNAU
LL48,0,PENRHYNDEUDRAETH
LL49,0,PORTHMADOG
LL51,0,GARNDOLBENMAEN
LL52,0,CRICCIETH
LL53,0,PWLLHELI
LL54,0,CAERNARFON
LL55,0,CAERNARFON
LL56,0,Y FELINHELI
LL57,0,BANGOR
LL58,0,BEAUMARIS
LL59,0,MENAI BRIDGE
LL60,0,GAERWEN
LL61,0,LLANFAIRPWLLGWYNGYLL
LL62,0,BODORGAN
LL63,0,TY CROES
LL64,0,RHOSNEIGR
LL65,0,HOLYHEAD
LL66,0,RHOSGOCH
LL67,0,CEMAES BAY
LL68,0,AMLWCH
LL69,0,PENYSARN
LL70,0,DULAS
LL71,0,LLANERCHYMEDD
LL72,0,MOELFRE
LL73,0,MARIANGLAS
LL74,0,TYN-Y-GONGL
LL75,0,PENTRAETH
LL76,0,LLANBEDRGOCH
LL77,1,RHOSNEIGR,LLANGEFNI
LL78,0,BRYNTEG
LN1,0,LINCOLN
LN2,0,LINCOLN
LN3,0,LINCOLN
LN4,0,LINCOLN
LN5,0,LINCOLN
LN6,0,LINCOLN
LN7,0,MARKET RASEN
LN8,0,MARKET RASEN
LN9,0,HORNCASTLE
LN10,0,WOODHALL SPA
LN11,0,LOUTH
LN12,0,MABLETHORPE
LN13,0,ALFORD
LS1,0,LEEDS
LS2,0,LEEDS
LS3,0,LEEDS
LS4,0,LEEDS
LS5,0,LEEDS
LS6,0,LEEDS
LS7,0,LEEDS
LS8,0,LEEDS
LS9,0,LEEDS
LS10,0,LEEDS
LS11,0,LEEDS
LS12,0,LEEDS
LS13,0,LEEDS
LS14,0,LEEDS
LS15,0,LEEDS
LS16,0,LEEDS
LS17,0,LEEDS
LS18,0,LEEDS
LS19,0,LEEDS
LS20,0,LEEDS
LS21,0,OTLEY
LS22,0,WETHERBY
LS23,0,WETHERBY
LS24,0,TADCASTER
LS25,0,LEEDS
LS26,0,LEEDS
LS27,0,LEEDS
LS28,0,PUDSEY
LS29,0,ILKLEY
LS88,1,LEEDS
LS98,1,LEEDS
LS99,1,LEEDS
LU1,0,LUTON
LU2,0,LUTON
LU3,0,LUTON
LU4,0,LUTON
LU5,0,DUNSTABLE
LU6,0,DUNSTABLE
LU7,0,LEIGHTON BUZZARD
M1,0,MANCHESTER
M2,0,MANCHESTER
M3,0,MANCHESTER,SALFORD
M4,0,MANCHESTER
M5,0,SALFORD
M6,0,SALFORD
M7,0,SALFORD
M8,0,MANCHESTER
M9,0,MANCHESTER
M11,0,MANCHESTER
M12,0,MANCHESTER
M13,0,MANCHESTER
M14,0,MANCHESTER
M15,0,MANCHESTER
M16,0,MANCHESTER
M17,0,MANCHESTER
M18,0,MANCHESTER
M19,0,MANCHESTER
M20,0,MANCHESTER
M21,0,MANCHESTER
M22,0,MANCHESTER
M23,0,MANCHESTER
M24,0,MANCHESTER
M25,0,MANCHESTER
M26,0,MANCHESTER
M27,0,MANCHESTER
M28,0,MANCHESTER
M29,0,MANCHESTER
M30,0,MANCHESTER
M31,0,MANCHESTER
M32,0,MANCHESTER
M33,0,SALE
M34,0,MANCHESTER
M35,0,MANCHESTER
M38,0,MANCHESTER
M40,0,MANCHESTER
M41,0,MANCHESTER
M43,0,MANCHESTER
M44,0,MANCHESTER
M45,0,MANCHESTER
M46,0,MANCHESTER
M50,0,SALFORD
M60,1,MANCHESTER,SALFORD
M61,1,MANCHESTER
M90,0,MANCHESTER
M99,1,MANCHESTER
ME1,0,ROCHESTER
ME2,0,ROCHESTER
ME3,0,ROCHESTER
ME4,0,CHATHAM
ME5,0,CHATHAM
ME6,0,AYLESFORD,SNODLAND,WEST MALLING
ME7,0,GILLINGHAM
ME8,0,GILLINGHAM
ME9,0,SITTINGBOURNE
ME10,0,SITTINGBOURNE
ME11,0,QUEENBOROUGH
ME12,0,SHEERNESS
ME13,0,FAVERSHAM
ME14,0,MAIDSTONE
ME15,0,MAIDSTONE
ME16,0,MAIDSTONE
ME17,0,MAIDSTONE
ME18,0,MAIDSTONE
ME19,0,WEST MALLING
ME20,0,AYLESFORD
ME99,1,MAIDSTONE
MK1,0,MILTON KEYNES
MK2,0,MILTON KEYNES
MK3,0,MILTON KEYNES
MK4,0,MILTON KEYNES
MK5,0,MILTON KEYNES
MK6,0,MILTON KEYNES
MK7,0,MILTON KEYNES
MK8,0,MILTON KEYNES
MK9,0,MILTON KEYNES
MK10,0,MILTON KEYNES
MK11,0,MILTON KEYNES
MK12,0,MILTON KEYNES
MK13,0,MILTON KEYNES
MK14,0,MILTON KEYNES
MK15,0,MILTON KEYNES
MK16,0,NEWPORT PAGNELL
MK17,0,MILTON KEYNES
MK18,0,BUCKINGHAM
MK19,0,MILTON KEYNES
MK40,0,BEDFORD
MK41,0,BEDFORD
MK42,0,BEDFORD
MK43,0,BEDFORD
MK44,0,BEDFORD
MK45,0,BEDFORD
MK46,0,OLNEY
MK77,1,MILTON KEYNES
ML1,0,MOTHERWELL
ML2,0,WISHAW
ML3,0,HAMILTON
ML4,0,BELLSHILL
ML5,0,COATBRIDGE
ML6,0,AIRDRIE
ML7,0,SHOTTS
ML8,0,CARLUKE
ML9,0,LARKHALL
ML10,0,STRATHAVEN
ML11,0,LANARK
ML12,0,BIGGAR
N1C,0,LONDON
N1P,1,LONDON
N1,0,LONDON
N2,0,LONDON
N3,0,LONDON
N4,0,LONDON
N5,0,LONDON
N6,0,LONDON
N7,0,LONDON
N8,0,LONDON
N9,0,LONDON
N10,0,LONDON
N11,0,LONDON
N12,0,LONDON
N13,0,LONDON
N14,0,LONDON
N15,0,LONDON
N16,0,LONDON
N17,0,LONDON
N18,0,LONDON
N19,0,LONDON
N20,0,LONDON
N21,0,LONDON
N22,0,LONDON
N81,1,LONDON
NE1,0,NEWCASTLE UPON TYNE
NE2,0,NEWCASTLE UPON TYNE
NE3,0,NEWCASTLE UPON TYNE
NE4,0,NEWCASTLE UPON TYNE
NE5,0,NEWCASTLE UPON TYNE
NE6,0,NEWCASTLE UPON TYNE
NE7,0,NEWCASTLE UPON TYNE
NE8,0,GATESHEAD
NE9,0,GATESHEAD
NE10,0,GATESHEAD
NE11,0,GATESHEAD
NE12,0,NEWCASTLE UPON TYNE
NE13,0,NEWCASTLE UPON TYNE
NE15,0,NEWCASTLE UPON TYNE
NE16,0,NEWCASTLE UPON TYNE
NE17,0,NEWCASTLE UPON TYNE
NE18,0,NEWCASTLE UPON TYNE
NE19,0,NEWCASTLE UPON TYNE
NE20,0,NEWCASTLE UPON TYNE
NE21,0,BLAYDON-ON-TYNE
NE22,0,BEDLINGTON
NE23,0,CRAMLINGTON
NE24,0,BLYTH
NE25,0,WHITLEY BAY
NE26,0,WHITLEY BAY
NE27,0,NEWCASTLE UPON TYNE
NE28,0,WALLSEND
NE29,0,NORTH SHIELDS
NE30,0,NORTH SHIELDS
NE31,0,HEBBURN
NE32,0,JARROW
NE33,0,SOUTH SHIELDS
NE34,0,SOUTH SHIELDS
NE35,0,BOLDON COLLIERY
NE36,0,EAST BOLDON
NE37,0,WASHINGTON
NE38,0,WASHINGTON
NE39,0,ROWLANDS GILL
NE40,0,RYTON
NE41,0,WYLAM
NE42,0,PRUDHOE
NE43,0,STOCKSFIELD
NE44,0,RIDING MILL
NE45,0,CORBRIDGE
NE46,0,HEXHAM
NE47,0,HEXHAM
NE48,0,HEXHAM
NE49,0,HALTWHISTLE
NE61,0,MORPETH
NE62,0,CHOPPINGTON
NE63,0,ASHINGTON
NE64,0,NEWBIGGIN-BY-THE-SEA
NE65,0,MORPETH
NE66,0,ALNWICK,BAMBURGH
NE67,0,CHATHILL
NE68,0,SEAHOUSES
NE69,0,BAMBURGH
NE70,0,BELFORD
NE71,0,WOOLER
NE82,1,NEWCASTLE UPON TYNE
NE83,1,NEWCASTLE UPON TYNE
NE85,1,NEWCASTLE UPON TYNE
NE88,1,NEWCASTLE UPON TYNE
NE92,1,GATESHEAD
NE98,1,NEWCASTLE UPON TYNE
NE99,1,NEWCASTLE UPON TYNE
NG1,0,NOTTINGHAM
NG2,0,NOTTINGHAM
NG3,0,NOTTINGHAM
NG4,0,NOTTINGHAM
NG5,0,NOTTINGHAM
NG6,0,NOTTINGHAM
NG7,0,NOTTINGHAM
NG8,0,NOTTINGHAM
NG9,0,NOTTINGHAM
NG10,0,NOTTINGHAM
NG11,0,NOTTINGHAM
NG12,0,NOTTINGHAM
NG13,0,NOTTINGHAM
NG14,0,NOTTINGHAM
NG15,0,NOTTINGHAM
NG16,0,NOTTINGHAM
NG17,0,NOTTINGHAM,SUTTON-IN-ASHFIELD
NG18,0,MANSFIELD
NG19,0,MANSFIELD
NG20,0,MANSFIELD
NG21,0,MANSFIELD
NG22,0,NEWARK
NG23,0,NEWARK
NG24,0,NEWARK
NG25,0,SOUTHWELL
NG31,0,GRANTHAM
NG32,0,GRANTHAM
NG33,0,GRANTHAM
NG34,0,SLEAFORD
NG70,1,MANSFIELD
NG80,1,NOTTINGHAM
NG90,1,NOTTINGHAM
NN1,0,NORTHAMPTON
NN2,0,NORTHAMPTON
NN3,0,NORTHAMPTON
NN4,0,NORTHAMPTON
NN5,0,NORTHAMPTON
NN6,0,NORTHAMPTON
NN7,0,NORTHAMPTON
NN8,0,WELLINGBOROUGH
NN9,0,WELLINGBOROUGH
NN10,0,RUSHDEN
NN11,0,DAVENTRY
NN12,0,TOWCESTER
NN13,0,BRACKLEY
NN14,0,KETTERING
NN15,0,KETTERING
NN16,0,KETTERING
NN17,0,CORBY
NN18,0,CORBY
NN29,0,WELLINGBOROUGH
NP4,0,PONTYPOOL
NP7,0,ABERGAVENNY,CRICKHOWELL
NP8,0,CRICKHOWELL
NP10,0,NEWPORT
NP11,0,NEWPORT
NP12,0,BLACKWOOD
NP13,0,ABERTILLERY
NP15,0,USK
NP16,0,CHEPSTOW
NP18,0,NEWPORT
NP19,0,NEWPORT
NP20,0,NEWPORT
NP22,0,TREDEGAR
NP23,0,EBBW VALE
NP24,0,NEW TREDEGAR
NP25,0,MONMOUTH
NP26,0,CALDICOT
NP44,0,CWMBRAN
NR1,0,NORWICH
NR2,0,NORWICH
NR3,0,NORWICH
NR4,0,NORWICH
NR5,0,NORWICH
NR6,0,NORWICH
NR7,0,NORWICH
NR8,0,NORWICH
NR9,0,NORWICH
NR10,0,NORWICH
NR11,0,NORWICH
NR12,0,NORWICH
NR13,0,NORWICH
NR14,0,NORWICH
NR15,0,NORWICH
NR16,0,NORWICH
NR17,0,ATTLEBOROUGH
NR18,1,NORWICH,WYMONDHAM
NR19,1,NORWICH,DEREHAM
NR20,0,DEREHAM
NR21,0,FAKENHAM
NR22,0,WALSINGHAM
NR23,0,WELLS-NEXT-THE-SEA
NR24,0,MELTON CONSTABLE
NR25,0,HOLT
NR26,1,NORWICH,SHERINGHAM
NR27,0,CROMER
NR28,1,NORWICH,NORTH WALSHAM
NR29,0,GREAT YARMOUTH
NR30,0,GREAT YARMOUTH
NR31,0,GREAT YARMOUTH
NR32,0,LOWESTOFT
NR33,0,LOWESTOFT
NR34,0,BECCLES
NR35,0,BUNGAY
NR99,1,NORWICH
NW1,0,LONDON
NW1W,1,LONDON
NW2,0,LONDON
NW3,0,LONDON
NW4,0,LONDON
NW5,0,LONDON
NW6,0,LONDON
NW7,0,LONDON
NW8,0,LONDON
NW9,0,LONDON
NW10,0,LONDON
NW11,0,LONDON
NW26,1,LONDON
OL1,0,OLDHAM
OL2,0,OLDHAM
OL3,0,OLDHAM
OL4,0,OLDHAM
OL5,0,ASHTON-UNDER-LYNE
OL6,0,ASHTON-UNDER-LYNE
OL7,0,ASHTON-UNDER-LYNE
OL8,0,OLDHAM
OL9,0,OLDHAM
OL10,0,HEYWOOD
OL11,0,ROCHDALE
OL12,0,ROCHDALE
OL13,0,BACUP
OL14,0,TODMORDEN
OL15,0,LITTLEBOROUGH
OL16,0,ROCHDALE,LITTLEBOROUGH
OL95,1,OLDHAM
OX1,0,OXFORD
OX2,0,OXFORD
OX3,0,OXFORD
OX4,0,OXFORD
OX5,0,KIDLINGTON
OX7,0,CHIPPING NORTON
OX9,0,THAME
OX10,0,WALLINGFORD
OX11,0,DIDCOT
OX12,0,WANTAGE
OX13,0,ABINGDON
OX14,0,ABINGDON
OX15,0,BANBURY
OX16,0,BANBURY
OX17,0,BANBURY
OX18,0,BAMPTON,BURFORD,CARTERTON
OX20,0,WOODSTOCK
OX25,0,BICESTER
OX26,0,BICESTER
OX27,0,BICESTER
OX28,0,WITNEY
OX29,0,WITNEY
OX33,0,OXFORD
OX39,0,CHINNOR
OX44,0,OXFORD
OX49,0,WATLINGTON
PA1,0,PAISLEY
PA2,0,PAISLEY
PA3,0,PAISLEY
PA4,0,RENFREW
PA5,0,JOHNSTONE
PA6,0,JOHNSTONE
PA7,0,BISHOPTON
PA8,0,ERSKINE
PA9,0,JOHNSTONE
PA10,0,JOHNSTONE
PA11,0,BRIDGE OF WEIR
PA12,0,LOCHWINNOCH
PA13,0,KILMACOLM
PA14,0,PORT GLASGOW
PA15,0,GREENOCK
PA16,0,GREENOCK
PA17,0,SKELMORLIE
PA18,0,WEMYSS BAY
PA19,0,GOUROCK
PA20,0,ISLE OF BUTE
PA21,0,TIGHNABRUAICH
PA22,0,COLINTRAIVE
PA23,0,DUNOON
PA24,0,CAIRNDOW
PA25,0,CAIRNDOW
PA26,0,CAIRNDOW
PA27,0,CAIRNDOW
PA28,0,CAMPBELTOWN
PA29,0,TARBERT
PA30,0,LOCHGILPHEAD
PA31,0,LOCHGILPHEAD
PA32,0,INVERARAY
PA33,0,DALMALLY
PA34,0,OBAN
PA35,0,TAYNUILT
PA36,0,BRIDGE OF ORCHY
PA37,0,OBAN
PA38,0,APPIN
PA41,0,ISLE OF GIGHA
PA42,0,ISLE OF ISLAY
PA43,0,ISLE OF ISLAY
PA44,0,ISLE OF ISLAY
PA45,0,ISLE OF ISLAY
PA46,0,ISLE OF ISLAY
PA47,0,ISLE OF ISLAY
PA48,0,ISLE OF ISLAY
PA49,0,ISLE OF ISLAY
PA60,0,ISLE OF JURA
PA61,0,ISLE OF COLONSAY
PA62,0,ISLE OF MULL
PA63,0,ISLE OF MULL
PA64,0,ISLE OF MULL
PA65,0,ISLE OF MULL
PA66,0,ISLE OF MULL
PA67,0,ISLE OF MULL
PA68,0,ISLE OF MULL
PA69,0,ISLE OF MULL
PA70,0,ISLE OF MULL
PA71,0,ISLE OF MULL
PA72,0,ISLE OF MULL
PA73,0,ISLE OF MULL
PA74,0,ISLE OF MULL
PA75,0,ISLE OF MULL
PA76,0,ISLE OF IONA
PA77,0,ISLE OF TIREE
PA78,0,ISLE OF COLL
PA80,0,OBAN
PE1,0,PETERBOROUGH
PE2,0,PETERBOROUGH
PE3,0,PETERBOROUGH
PE4,0,PETERBOROUGH
PE5,0,PETERBOROUGH
PE6,0,PETERBOROUGH
PE7,0,PETERBOROUGH
PE8,0,PETERBOROUGH
PE9,0,STAMFORD
PE10,0,BOURNE
PE11,0,SPALDING
PE12,0,SPALDING
PE13,0,WISBECH
PE14,0,WISBECH
PE15,0,MARCH
PE16,0,CHATTERIS
PE19,0,ST. NEOTS
PE20,0,BOSTON
PE21,0,BOSTON
PE22,0,BOSTON
PE23,0,SPILSBY
PE24,0,SKEGNESS
PE25,0,SKEGNESS
PE26,0,HUNTINGDON
PE27,0,ST. IVES
PE28,0,HUNTINGDON
PE29,0,HUNTINGDON
PE30,0,KING'S LYNN
PE31,0,KING'S LYNN
PE32,0,KING'S LYNN
PE33,0,KING'S LYNN
PE34,0,KING'S LYNN
PE35,0,SANDRINGHAM
PE36,0,HUNSTANTON
PE37,0,SWAFFHAM
PE38,0,DOWNHAM MARKET
PE99,1,PETERBOROUGH
PH1,0,PERTH
PH2,0,PERTH
PH3,0,AUCHTERARDER
PH4,0,AUCHTERARDER
PH5,0,CRIEFF
PH6,0,CRIEFF
PH7,0,CRIEFF
PH8,0,DUNKELD
PH9,0,PITLOCHRY
PH10,0,BLAIRGOWRIE
PH11,0,BLAIRGOWRIE
PH12,0,BLAIRGOWRIE
PH13,0,BLAIRGOWRIE
PH14,0,PERTH
PH15,0,ABERFELDY
PH16,0,PITLOCHRY
PH17,0,PITLOCHRY
PH18,0,PITLOCHRY
PH19,0,DALWHINNIE
PH20,0,NEWTONMORE
PH21,0,KINGUSSIE
PH22,0,AVIEMORE
PH23,0,CARRBRIDGE
PH24,0,BOAT OF GARTEN
PH25,0,NETHY BRIDGE
PH26,0,GRANTOWN-ON-SPEY
PH30,0,CORROUR
PH31,0,ROY BRIDGE
PH32,0,FORT AUGUSTUS
PH33,0,FORT WILLIAM
PH34,0,SPEAN BRIDGE
PH35,0,INVERGARRY
PH36,0,ACHARACLE
PH37,0,GLENFINNAN
PH38,0,LOCHAILORT
PH39,0,ARISAIG
PH40,0,MALLAIG
PH41,0,MALLAIG
PH42,0,ISLE OF EIGG
PH43,0,ISLE OF RUM
PH44,0,ISLE OF CANNA
PH49,0,BALLACHULISH
PH50,0,KINLOCHLEVEN
PL1,0,PLYMOUTH
PL2,0,PLYMOUTH
PL3,0,PLYMOUTH
PL4,0,PLYMOUTH
PL5,0,PLYMOUTH
PL6,0,PLYMOUTH
PL7,0,PLYMOUTH
PL8,0,PLYMOUTH
PL9,0,PLYMOUTH
PL10,0,TORPOINT
PL11,0,TORPOINT
PL12,0,SALTASH
PL13,0,LOOE
PL14,0,LISKEARD
PL15,0,LAUNCESTON
PL16,0,LIFTON
PL17,0,CALLINGTON
PL18,0,CALSTOCK,GUNNISLAKE
PL19,0,TAVISTOCK
PL20,0,YELVERTON
PL21,0,IVYBRIDGE
PL22,0,LOSTWITHIEL
PL23,0,FOWEY
PL24,0,PAR
PL25,0,ST. AUSTELL
PL26,0,ST. AUSTELL
PL27,0,WADEBRIDGE
PL28,0,PADSTOW
PL29,0,PORT ISAAC
PL30,0,BODMIN
PL31,0,BODMIN
PL32,0,CAMELFORD
PL33,0,DELABOLE
PL34,0,TINTAGEL
PL35,0,BOSCASTLE
PL95,1,PLYMOUTH
PO1,0,PORTSMOUTH
PO2,0,PORTSMOUTH
PO3,0,PORTSMOUTH
PO4,0,SOUTHSEA
PO5,0,SOUTHSEA
PO6,0,PORTSMOUTH
PO7,0,WATERLOOVILLE
PO8,0,WATERLOOVILLE
PO9,0,HAVANT,ROWLAND'S CASTLE
PO10,0,EMSWORTH
PO11,0,HAYLING ISLAND
PO12,0,GOSPORT,LEE-ON-THE-SOLENT
PO13,0,GOSPORT,LEE-ON-THE-SOLENT
PO14,0,FAREHAM
PO15,0,FAREHAM
PO16,0,FAREHAM
PO17,0,FAREHAM
PO18,0,CHICHESTER
PO19,0,CHICHESTER
PO20,0,CHICHESTER
PO21,0,BOGNOR REGIS
PO22,0,BOGNOR REGIS
PO30,0,NEWPORT,YARMOUTH
PO31,0,COWES
PO32,0,EAST COWES
PO33,0,RYDE
PO34,0,SEAVIEW
PO35,0,BEMBRIDGE
PO36,0,SANDOWN,SHANKLIN
PO37,0,SHANKLIN
PO38,0,VENTNOR
PO39,0,TOTLAND BAY
PO40,0,FRESHWATER
PO41,0,YARMOUTH
PR0,1,PRESTON
PR1,0,PRESTON
PR2,0,PRESTON
PR3,0,PRESTON
PR4,0,PRESTON
PR5,0,PRESTON
PR6,0,CHORLEY
PR7,0,CHORLEY
PR8,0,SOUTHPORT
PR9,0,SOUTHPORT
PR11,1,PRESTON
PR25,0,LEYLAND
PR26,0,LEYLAND
RG1,0,READING
RG2,0,READING
RG4,0,READING
RG5,0,READING
RG6,0,READING
RG7,0,READING
RG8,0,READING
RG9,0,HENLEY-ON-THAMES
RG10,0,READING
RG12,0,BRACKNELL
RG14,0,NEWBURY
RG17,0,HUNGERFORD
RG18,0,THATCHAM
RG19,0,READING,THATCHAM
RG20,0,NEWBURY
RG21,0,BASINGSTOKE
RG22,0,BASINGSTOKE
RG23,0,BASINGSTOKE
RG24,0,BASINGSTOKE
RG25,0,BASINGSTOKE
RG26,0,TADLEY
RG27,0,HOOK
RG28,0,BASINGSTOKE,WHITCHURCH
RG29,0,HOOK
RG30,0,READING
RG31,0,READING
RG40,0,WOKINGHAM
RG41,0,WOKINGHAM
RG42,0,BRACKNELL
RG45,0,CROWTHORNE
RH1,0,REDHILL
RH2,0,REIGATE
RH3,0,BETCHWORTH
RH4,0,BETCHWORTH,DORKING
RH5,0,DORKING
RH6,0,GATWICK,HORLEY
RH7,0,LINGFIELD
RH8,0,OXTED
RH9,0,GODSTONE
RH10,0,CRAWLEY
RH11,0,CRAWLEY
RH12,0,HORSHAM
RH13,0,HORSHAM
RH14,0,BILLINGSHURST
RH15,0,BURGESS HILL
RH16,0,HAYWARDS HEATH
RH17,0,HAYWARDS HEATH
RH18,0,FOREST ROW
RH19,0,EAST GRINSTEAD
RH20,0,PULBOROUGH
RH77,1,CRAWLEY
RM1,0,ROMFORD
RM2,0,ROMFORD
RM3,0,ROMFORD
RM4,0,ROMFORD
RM5,0,ROMFORD
RM6,0,ROMFORD
RM7,0,ROMFORD
RM8,0,DAGENHAM
RM9,0,DAGENHAM
RM10,0,DAGENHAM
RM11,0,HORNCHURCH
RM12,0,HORNCHURCH
RM13,0,RAINHAM
RM14,0,UPMINSTER
RM15,0,SOUTH OCKENDON
RM16,0,GRAYS
RM17,0,GRAYS
RM18,0,TILBURY
RM19,0,PURFLEET
RM20,0,GRAYS
S1,0,SHEFFIELD
S2,0,SHEFFIELD
S3,0,SHEFFIELD
S4,0,SHEFFIELD
S5,0,SHEFFIELD
S6,0,SHEFFIELD
S7,0,SHEFFIELD
S8,0,SHEFFIELD
S9,0,SHEFFIELD
S10,0,SHEFFIELD
S11,0,SHEFFIELD
S12,0,SHEFFIELD
S13,0,SHEFFIELD
S14,0,SHEFFIELD
S17,0,SHEFFIELD
S18,0,DRONFIELD
S20,0,SHEFFIELD
S21,0,SHEFFIELD
S25,0,SHEFFIELD
S26,0,SHEFFIELD
S32,0,HOPE VALLEY
S33,0,HOPE VALLEY
S35,0,SHEFFIELD
S36,0,SHEFFIELD
S40,0,CHESTERFIELD
S41,0,CHESTERFIELD
S42,0,CHESTERFIELD
S43,0,CHESTERFIELD
S44,0,CHESTERFIELD
S45,0,CHESTERFIELD
S49,1,CHESTERFIELD
S60,0,ROTHERHAM
S61,0,ROTHERHAM
S62,0,ROTHERHAM
S63,0,ROTHERHAM
S64,0,MEXBOROUGH
S65,0,ROTHERHAM
S66,0,ROTHERHAM
S70,0,BARNSLEY
S71,0,BARNSLEY
S72,0,BARNSLEY
S73,0,BARNSLEY
S74,0,BARNSLEY
S75,0,BARNSLEY
S80,0,WORKSOP
S81,0,WORKSOP
S95,1,SHEFFIELD
S96,1,SHEFFIELD
S97,1,SHEFFIELD,ROTHERHAM
S98,1,SHEFFIELD
S99,1,SHEFFIELD
SA1,0,SWANSEA
SA2,0,SWANSEA
SA3,0,SWANSEA
SA4,0,SWANSEA
SA5,0,SWANSEA
SA6,0,SWANSEA
SA7,0,SWANSEA
SA8,0,SWANSEA
SA9,0,SWANSEA
SA10,0,NEATH
SA11,0,NEATH
SA12,0,PORT TALBOT
SA13,0,PORT TALBOT
SA14,0,LLANELLI
SA15,0,LLANELLI
SA16,0,BURRY PORT
SA17,0,FERRYSIDE,KIDWELLY
SA18,0,AMMANFORD
SA19,0,LLANDEILO,LLANGADOG,LLANWRDA
SA20,0,LLANDOVERY
SA31,0,CARMARTHEN
SA32,0,CARMARTHEN
SA33,0,CARMARTHEN
SA34,0,WHITLAND
SA35,0,LLANFYRNACH
SA36,0,GLOGUE
SA37,0,BONCATH
SA38,0,NEWCASTLE EMLYN
SA39,0,PENCADER
SA40,0,LLANYBYDDER
SA41,0,CRYMYCH
SA42,0,NEWPORT
SA43,0,CARDIGAN
SA44,0,LLANDYSUL
SA45,0,NEW QUAY
SA46,0,ABERAERON
SA47,0,LLANARTH
SA48,0,ABERAERON,LAMPETER
SA61,0,HAVERFORDWEST
SA62,0,HAVERFORDWEST
SA63,0,CLARBESTON ROAD
SA64,0,GOODWICK
SA65,0,FISHGUARD
SA66,0,CLYNDERWEN
SA67,0,NARBERTH
SA68,0,KILGETTY
SA69,0,SAUNDERSFOOT
SA70,0,TENBY
SA71,0,PEMBROKE
SA72,1,PEMBROKE,PEMBROKE DOCK
SA73,0,MILFORD HAVEN
SA80,1,SWANSEA
SA99,1,SWANSEA
SE1,0,LONDON
SE1P,1,LONDON
SE2,0,LONDON
SE3,0,LONDON
SE4,0,LONDON
SE5,0,LONDON
SE6,0,LONDON
SE7,0,LONDON
SE8,0,LONDON
SE9,0,LONDON
SE10,0,LONDON
SE11,0,LONDON
SE12,0,LONDON
SE13,0,LONDON
SE14,0,LONDON
SE15,0,LONDON
SE16,0,LONDON
SE17,0,LONDON
SE18,0,LONDON
SE19,0,LONDON
SE20,0,LONDON
SE21,0,LONDON
SE22,0,LONDON
SE23,0,LONDON
SE24,0,LONDON
SE25,0,LONDON
SE26,0,LONDON
SE27,0,LONDON
SE28,0,LONDON
SG1,0,STEVENAGE
SG2,0,STEVENAGE
SG3,0,KNEBWORTH
SG4,0,HITCHIN
SG5,0,HITCHIN
SG6,1,HITCHIN,LETCHWORTH GARDEN CITY
SG7,0,BALDOCK
SG8,0,ROYSTON
SG9,0,BUNTINGFORD
SG10,0,MUCH HADHAM
SG11,0,WARE
SG12,0,WARE
SG13,0,HERTFORD
SG14,0,HERTFORD
SG15,0,ARLESEY
SG16,0,HENLOW
SG17,0,SHEFFORD
SG18,0,BIGGLESWADE
SG19,0,SANDY
SK1,0,STOCKPORT
SK2,0,STOCKPORT
SK3,0,STOCKPORT
SK4,0,STOCKPORT
SK5,0,STOCKPORT
SK6,0,STOCKPORT
SK7,0,STOCKPORT
SK8,0,CHEADLE
SK9,0,ALDERLEY EDGE,WILMSLOW
SK10,0,MACCLESFIELD
SK11,0,MACCLESFIELD
SK12,0,STOCKPORT
SK13,0,GLOSSOP
SK14,0,HYDE
SK15,0,STALYBRIDGE
SK16,0,DUKINFIELD
SK17,0,BUXTON
SK22,0,HIGH PEAK
SK23,0,HIGH PEAK
SL0,0,IVER
SL1,0,SLOUGH
SL2,0,SLOUGH
SL3,0,SLOUGH
SL4,0,WINDSOR
SL5,0,ASCOT
SL6,0,MAIDENHEAD
SL7,0,MARLOW
SL8,0,BOURNE END
SL9,0,GERRARDS CROSS
SL60,1,MAIDENHEAD
SL95,1,SLOUGH
SM1,0,SUTTON
SM2,0,SUTTON
SM3,0,SUTTON
SM4,0,MORDEN
SM5,0,CARSHALTON
SM6,0,WALLINGTON
SM7,0,BANSTEAD
SN1,0,SWINDON
SN2,0,SWINDON
SN3,0,SWINDON
SN4,0,SWINDON
SN5,0,SWINDON
SN6,0,SWINDON
SN7,0,FARINGDON
SN8,0,MARLBOROUGH
SN9,0,PEWSEY
SN10,0,DEVIZES
SN11,0,CALNE
SN12,0,MELKSHAM
SN13,0,CORSHAM
SN14,0,CHIPPENHAM
SN15,1,CORSHAM,CHIPPENHAM
SN16,0,MALMESBURY
SN25,0,SWINDON
SN26,0,SWINDON
SN38,1,SWINDON
SN99,1,SWINDON
SO14,0,SOUTHAMPTON
SO15,0,SOUTHAMPTON
SO16,0,SOUTHAMPTON
SO17,0,SOUTHAMPTON
SO18,0,SOUTHAMPTON
SO19,0,SOUTHAMPTON
SO20,0,STOCKBRIDGE
SO21,0,WINCHESTER
SO22,0,WINCHESTER
SO23,0,WINCHESTER
SO24,0,ALRESFORD
SO25,1,WINCHESTER
SO30,0,SOUTHAMPTON
SO31,0,SOUTHAMPTON
SO32,0,SOUTHAMPTON
SO40,0,SOUTHAMPTON,LYNDHURST
SO41,0,LYMINGTON
SO42,0,BROCKENHURST
SO43,0,LYNDHURST
SO45,0,SOUTHAMPTON
SO50,0,EASTLEIGH
SO51,0,ROMSEY
SO52,0,SOUTHAMPTON
SO53,0,EASTLEIGH
SO97,1,SOUTHAMPTON
SP1,0,SALISBURY
SP2,0,SALISBURY
SP3,0,SALISBURY
SP4,0,SALISBURY
SP5,0,SALISBURY
SP6,0,FORDINGBRIDGE
SP7,0,SHAFTESBURY
SP8,0,GILLINGHAM
SP9,0,TIDWORTH
SP10,0,ANDOVER
SP11,0,ANDOVER
SR1,0,SUNDERLAND
SR2,0,SUNDERLAND
SR3,0,SUNDERLAND
SR4,0,SUNDERLAND
SR5,0,SUNDERLAND
SR6,0,SUNDERLAND
SR7,0,SEAHAM
SR8,0,PETERLEE
SR9,1,SUNDERLAND
SS0,0,WESTCLIFF-ON-SEA
SS1,0,WESTCLIFF-ON-SEA,SOUTHEND-ON-SEA
SS2,0,SOUTHEND-ON-SEA
SS3,0,SOUTHEND-ON-SEA
SS4,0,ROCHFORD
SS5,0,HOCKLEY
SS6,0,RAYLEIGH
SS7,0,BENFLEET
SS8,0,CANVEY ISLAND
SS9,0,LEIGH-ON-SEA
SS11,0,WICKFORD
SS12,0,WICKFORD
SS13,0,BASILDON
SS14,0,BASILDON
SS15,0,BASILDON
SS16,0,BASILDON
SS17,0,STANFORD-LE-HOPE
SS22,1,SOUTHEND-ON-SEA
SS99,1,SOUTHEND-ON-SEA
ST1,0,STOKE-ON-TRENT
ST2,0,STOKE-ON-TRENT
ST3,0,STOKE-ON-TRENT
ST4,0,STOKE-ON-TRENT
ST5,0,NEWCASTLE
ST6,0,STOKE-ON-TRENT
ST7,0,STOKE-ON-TRENT
ST8,0,STOKE-ON-TRENT
ST9,0,STOKE-ON-TRENT
ST10,0,STOKE-ON-TRENT
ST11,0,STOKE-ON-TRENT
ST12,0,STOKE-ON-TRENT
ST13,0,LEEK
ST14,0,UTTOXETER
ST15,0,STONE
ST16,0,STAFFORD
ST17,0,STAFFORD
ST18,0,STAFFORD
ST19,0,STAFFORD
ST20,0,STAFFORD
ST21,0,STAFFORD
ST55,1,NEWCASTLE
SW1W,0,LONDON
SW1X,0,LONDON
SW1H,0,LONDON
SW1A,0,LONDON
SW1P,0,LONDON
SW1Y,0,LONDON
SW1E,0,LONDON
SW1V,0,LONDON
SW2,0,LONDON
SW3,0,LONDON
SW4,0,LONDON
SW5,0,LONDON
SW6,0,LONDON
SW7,0,LONDON
SW8,0,LONDON
SW9,0,LONDON
SW10,0,LONDON
SW11,0,LONDON
SW12,0,LONDON
SW13,0,LONDON
SW14,0,LONDON
SW15,0,LONDON
SW16,0,LONDON
SW17,0,LONDON
SW18,0,LONDON
SW19,0,LONDON
SW20,0,LONDON
SW95,1,LONDON
SY1,0,SHREWSBURY
SY2,0,SHREWSBURY
SY3,0,SHREWSBURY
SY4,0,SHREWSBURY
SY5,0,SHREWSBURY
SY6,0,CHURCH STRETTON
SY7,0,BUCKNELL,CRAVEN ARMS,LYDBURY NORTH
SY8,0,LUDLOW
SY9,0,BISHOPS CASTLE
SY10,0,OSWESTRY
SY11,0,OSWESTRY
SY12,0,ELLESMERE
SY13,0,WHITCHURCH
SY14,0,MALPAS
SY15,0,MONTGOMERY
SY16,0,NEWTOWN
SY17,0,CAERSWS,LLANDINAM
SY18,0,LLANIDLOES
SY19,0,LLANBRYNMAIR
SY20,0,MACHYNLLETH
SY21,0,WELSHPOOL
SY22,0,LLANFECHAIN,LLANFYLLIN,LLANSANFFRAID,LLANYMYNECH,MEIFOD
SY23,0,ABERYSTWYTH,LLANON,LLANRHYSTUD
SY24,0,BORTH,BOW STREET,TALYBONT
SY25,0,TREGARON,YSTRAD MEURIG
SY99,1,SHREWSBURY
TA1,0,TAUNTON
TA2,0,TAUNTON
TA3,0,TAUNTON
TA4,0,TAUNTON
TA5,0,BRIDGWATER
TA6,0,BRIDGWATER
TA7,0,BRIDGWATER
TA8,0,BURNHAM-ON-SEA
TA9,0,HIGHBRIDGE
TA10,0,LANGPORT
TA11,0,SOMERTON
TA12,0,MARTOCK
TA13,0,SOUTH PETHERTON
TA14,0,STOKE-SUB-HAMDON
TA15,0,MONTACUTE
TA16,0,MERRIOTT
TA17,0,HINTON ST. GEORGE
TA18,0,CREWKERNE
TA19,0,ILMINSTER
TA20,0,CHARD
TA21,0,WELLINGTON
TA22,0,DULVERTON
TA23,0,WATCHET
TA24,0,MINEHEAD
TD1,0,GALASHIELS
TD2,0,LAUDER
TD3,0,GORDON
TD4,0,EARLSTON
TD5,0,KELSO
TD6,0,MELROSE
TD7,0,SELKIRK
TD8,0,JEDBURGH
TD9,0,HAWICK,NEWCASTLETON
TD10,0,DUNS
TD11,0,DUNS
TD12,0,COLDSTREAM,CORNHILL-ON-TWEED,MINDRUM
TD13,0,COCKBURNSPATH
TD14,0,EYEMOUTH
TD15,0,BERWICK-UPON-TWEED
TF1,0,TELFORD
TF2,0,TELFORD
TF3,0,TELFORD
TF4,0,TELFORD
TF5,0,TELFORD
TF6,0,TELFORD
TF7,0,TELFORD
TF8,0,TELFORD
TF9,0,MARKET DRAYTON
TF10,0,NEWPORT
TF11,0,SHIFNAL
TF12,0,BROSELEY
TF13,0,MUCH WENLOCK
TN1,0,TUNBRIDGE WELLS
TN2,0,TUNBRIDGE WELLS,WADHURST
TN3,0,TUNBRIDGE WELLS
TN4,0,TUNBRIDGE WELLS
TN5,0,WADHURST
TN6,0,CROWBOROUGH
TN7,0,HARTFIELD
TN8,0,EDENBRIDGE
TN9,0,TONBRIDGE
TN10,0,TONBRIDGE
TN11,0,TONBRIDGE
TN12,0,TONBRIDGE
TN13,0,SEVENOAKS
TN14,0,SEVENOAKS
TN15,0,SEVENOAKS
TN16,0,WESTERHAM
TN17,0,CRANBROOK
TN18,0,CRANBROOK
TN19,0,ETCHINGHAM
TN20,0,MAYFIELD
TN21,0,HEATHFIELD
TN22,0,UCKFIELD
TN23,0,ASHFORD
TN24,0,ASHFORD
TN25,0,ASHFORD
TN26,0,ASHFORD
TN27,0,ASHFORD
TN28,0,NEW ROMNEY
TN29,0,ROMNEY MARSH
TN30,0,TENTERDEN
TN31,0,RYE
TN32,0,ROBERTSBRIDGE
TN33,0,BATTLE
TN34,0,HASTINGS
TN35,0,HASTINGS
TN36,0,WINCHELSEA
TN37,0,ST. LEONARDS-ON-SEA
TN38,0,ST. LEONARDS-ON-SEA
TN39,0,BEXHILL-ON-SEA
TN40,0,BEXHILL-ON-SEA
TQ1,0,TORQUAY
TQ2,0,TORQUAY
TQ3,0,PAIGNTON
TQ4,0,PAIGNTON
TQ5,0,BRIXHAM
TQ6,0,DARTMOUTH
TQ7,0,KINGSBRIDGE
TQ8,0,SALCOMBE
TQ9,0,TOTNES,SOUTH BRENT
TQ10,0,SOUTH BRENT
TQ11,0,BUCKFASTLEIGH
TQ12,0,NEWTON ABBOT
TQ13,0,NEWTON ABBOT
TQ14,0,TEIGNMOUTH
TR1,0,TRURO
TR2,0,TRURO
TR3,0,TRURO
TR4,0,TRURO
TR5,0,ST. AGNES
TR6,0,PERRANPORTH
TR7,0,NEWQUAY
TR8,0,NEWQUAY
TR9,0,ST. COLUMB
TR10,0,PENRYN
TR11,0,FALMOUTH
TR12,0,HELSTON
TR13,0,HELSTON
TR14,0,CAMBORNE
TR15,0,REDRUTH
TR16,0,REDRUTH
TR17,0,MARAZION
TR18,0,PENZANCE
TR19,0,PENZANCE
TR20,0,PENZANCE
TR21,0,ISLES OF SCILLY
TR22,0,ISLES OF SCILLY
TR23,0,ISLES OF SCILLY
TR24,0,ISLES OF SCILLY
TR25,0,ISLES OF SCILLY
TR26,0,ST. IVES
TR27,0,HAYLE
TS1,0,MIDDLESBROUGH
TS2,0,MIDDLESBROUGH
TS3,0,MIDDLESBROUGH
TS4,0,MIDDLESBROUGH
TS5,0,MIDDLESBROUGH
TS6,0,MIDDLESBROUGH
TS7,0,MIDDLESBROUGH
TS8,0,MIDDLESBROUGH
TS9,0,MIDDLESBROUGH
TS10,0,REDCAR
TS11,0,REDCAR
TS12,0,SALTBURN-BY-THE-SEA
TS13,0,SALTBURN-BY-THE-SEA
TS14,0,GUISBOROUGH
TS15,0,YARM
TS16,0,STOCKTON-ON-TEES
TS17,0,STOCKTON-ON-TEES
TS18,0,STOCKTON-ON-TEES
TS19,0,STOCKTON-ON-TEES
TS20,0,STOCKTON-ON-TEES
TS21,0,STOCKTON-ON-TEES
TS22,0,BILLINGHAM
TS23,0,BILLINGHAM
TS24,0,HARTLEPOOL
TS25,0,HARTLEPOOL
TS26,0,HARTLEPOOL
TS27,0,HARTLEPOOL
TS28,0,WINGATE
TS29,0,TRIMDON STATION
TW1,0,TWICKENHAM
TW2,0,TWICKENHAM
TW3,0,HOUNSLOW
TW4,0,HOUNSLOW
TW5,0,HOUNSLOW
TW6,0,HOUNSLOW
TW7,0,ISLEWORTH
TW8,0,BRENTFORD
TW9,0,RICHMOND
TW10,0,RICHMOND
TW11,0,TEDDINGTON
TW12,0,HAMPTON
TW13,0,FELTHAM
TW14,0,FELTHAM
TW15,0,ASHFORD
TW16,0,SUNBURY-ON-THAMES
TW17,0,SHEPPERTON
TW18,0,STAINES-UPON-THAMES
TW19,0,STAINES-UPON-THAMES
TW20,0,EGHAM
UB1,0,SOUTHALL
UB2,0,SOUTHALL
UB3,1,SOUTHALL,HAYES
UB4,0,HAYES
UB5,0,NORTHOLT,GREENFORD
UB6,0,GREENFORD
UB7,0,WEST DRAYTON
UB8,1,WEST DRAYTON,UXBRIDGE
UB9,0,UXBRIDGE
UB10,0,UXBRIDGE
UB11,0,UXBRIDGE
UB18,1,GREENFORD
W1S,0,LONDON
W1T,0,LONDON
W1J,0,LONDON
W1K,0,LONDON
W1A,1,LONDON
W1G,0,LONDON
W1F,0,LONDON
W1U,0,LONDON
W1C,0,LONDON
W1H,0,LONDON
W1B,0,LONDON
W1D,0,LONDON
W1W,0,LONDON
W2,0,LONDON
W3,0,LONDON
W4,0,LONDON
W5,0,LONDON
W6,0,LONDON
W7,0,LONDON
W8,0,LONDON
W9,0,LONDON
W10,0,LONDON
W11,0,LONDON
W12,0,LONDON
W13,0,LONDON
W14,0,LONDON
WA1,0,WARRINGTON
WA2,0,WARRINGTON
WA3,0,WARRINGTON
WA4,0,WARRINGTON
WA5,0,WARRINGTON
WA6,0,FRODSHAM
WA7,0,RUNCORN
WA8,0,WIDNES
WA9,0,ST. HELENS
WA10,0,ST. HELENS
WA11,0,ST. HELENS
WA12,0,NEWTON-LE-WILLOWS
WA13,0,LYMM
WA14,0,ALTRINCHAM
WA15,0,ALTRINCHAM
WA16,0,KNUTSFORD
WA55,1,WARRINGTON
WA88,1,WIDNES
WC1R,0,LONDON
WC1N,0,LONDON
WC1V,0,LONDON
WC1X,0,LONDON
WC1A,0,LONDON
WC1E,0,LONDON
WC1B,0,LONDON
WC1H,0,LONDON
WC2H,0,LONDON
WC2B,0,LONDON
WC2E,0,LONDON
WC2A,0,LONDON
WC2N,0,LONDON
WC2R,0,LONDON
WD3,0,RICKMANSWORTH
WD4,0,KINGS LANGLEY
WD5,0,ABBOTS LANGLEY
WD6,0,BOREHAMWOOD
WD7,0,RADLETT
WD17,0,WATFORD
WD18,1,KINGS LANGLEY,WATFORD
WD19,0,WATFORD
WD23,0,BUSHEY
WD24,0,WATFORD
WD25,0,WATFORD
WD99,1,WATFORD
WF1,0,WAKEFIELD
WF2,0,WAKEFIELD
WF3,0,WAKEFIELD
WF4,0,WAKEFIELD
WF5,0,OSSETT
WF6,0,NORMANTON
WF7,0,PONTEFRACT
WF8,0,PONTEFRACT
WF9,0,PONTEFRACT
WF10,0,NORMANTON,CASTLEFORD
WF11,0,KNOTTINGLEY
WF12,0,DEWSBURY
WF13,0,DEWSBURY
WF14,0,MIRFIELD
WF15,0,LIVERSEDGE
WF16,1,LIVERSEDGE,HECKMONDWIKE
WF17,0,BATLEY
WF90,1,WAKEFIELD
WN1,0,WIGAN
WN2,0,WIGAN
WN3,0,WIGAN
WN4,0,WIGAN
WN5,0,WIGAN
WN6,0,WIGAN
WN7,0,LEIGH
WN8,0,WIGAN,SKELMERSDALE
WR1,0,WORCESTER
WR2,0,WORCESTER
WR3,0,WORCESTER
WR4,0,WORCESTER
WR5,0,WORCESTER
WR6,0,WORCESTER
WR7,0,WORCESTER
WR8,0,WORCESTER
WR9,0,DROITWICH
WR10,0,PERSHORE
WR11,0,EVESHAM,BROADWAY
WR12,0,BROADWAY
WR13,0,MALVERN
WR14,0,MALVERN
WR15,0,TENBURY WELLS
WR78,1,WORCESTER
WR99,1,WORCESTER
WS1,0,WALSALL
WS2,0,WALSALL
WS3,0,WALSALL
WS4,0,WALSALL
WS5,0,WALSALL
WS6,0,WALSALL
WS7,0,BURNTWOOD
WS8,0,WALSALL
WS9,0,WALSALL
WS10,0,WEDNESBURY
WS11,0,CANNOCK
WS12,0,CANNOCK
WS13,0,LICHFIELD
WS14,0,LICHFIELD
WS15,0,RUGELEY
WV1,0,WOLVERHAMPTON,WILLENHALL
WV2,0,WOLVERHAMPTON
WV3,0,WOLVERHAMPTON
WV4,0,WOLVERHAMPTON
WV5,0,WOLVERHAMPTON
WV6,0,WOLVERHAMPTON
WV7,0,WOLVERHAMPTON
WV8,0,WOLVERHAMPTON
WV9,0,WOLVERHAMPTON
WV10,0,WOLVERHAMPTON
WV11,0,WOLVERHAMPTON
WV12,0,WILLENHALL
WV13,0,WILLENHALL
WV14,0,BILSTON
WV15,0,BRIDGNORTH
WV16,0,BRIDGNORTH
WV98,1,WOLVERHAMPTON
WV99,1,WOLVERHAMPTON
YO1,0,YORK
YO7,0,THIRSK
YO8,0,SELBY
YO10,0,YORK
YO11,0,SCARBOROUGH
YO12,0,SCARBOROUGH
YO13,0,SCARBOROUGH
YO14,0,FILEY
YO15,0,BRIDLINGTON
YO16,0,BRIDLINGTON
YO17,0,MALTON
YO18,0,PICKERING
YO19,0,YORK
YO21,0,WHITBY
YO22,0,WHITBY
YO23,0,YORK
YO24,0,YORK
YO25,0,DRIFFIELD
YO26,0,YORK
YO30,0,YORK
YO31,0,YORK
YO32,0,YORK
YO41,0,YORK
YO42,0,YORK
YO43,0,YORK
YO51,0,YORK
YO60,0,YORK
YO61,0,YORK
YO62,0,YORK
YO90,1,YORK
YO91,1,YORK
ZE1,0,SHETLAND
ZE2,0,SHETLAND
ZE3,0,SHETLAND

