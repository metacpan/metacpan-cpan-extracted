package Geo::UK::Postcode::Regex::Simple;

our $VERSION = '0.015';

use strict;
use warnings;

use Carp;

use base 'Exporter';

use Geo::UK::Postcode::Regex qw/ %REGEXES /;

our @EXPORT_OK = qw/ postcode_re extract_pc parse_pc validate_pc /;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $MODE             = 'strict';    # or 'valid' or 'lax'
our $PARTIAL          = 0;
our $ANCHORED         = 1;
our $CAPTURES         = 1;
our $CASE_INSENSITIVE = 0;

sub import {
    my $class = shift;

    my %tags = map { $_ => 1 } @_;

    $MODE
        = delete $tags{'-valid'}  ? 'valid'
        : delete $tags{'-lax'}    ? 'lax'
        : delete $tags{'-strict'} ? 'strict'
        :                           $MODE;

    $PARTIAL    #
        = delete $tags{'-partial'} ? 1
        : delete $tags{'-full'}    ? 0
        :                            $PARTIAL;
    $ANCHORED
        = delete $tags{'-unanchored'} ? 0
        : delete $tags{'-anchored'}   ? 1
        :                               $ANCHORED;
    $CAPTURES
        = delete $tags{'-nocaptures'} ? 0
        : delete $tags{'-captures'}   ? 1
        :                               $CAPTURES;

    $CASE_INSENSITIVE
        = delete $tags{'-case-insensitive'} ? 1
        : delete $tags{'-case-sensitive'}   ? 0
        :                                     $CASE_INSENSITIVE;

    local $Exporter::ExportLevel = 1;
    $class->SUPER::import( grep { /^[^\-]/ } keys %tags );
}

sub postcode_re {

    croak "invalid \$MODE $MODE" if $MODE !~ m/^(?:strict|lax|valid)$/;

    my $key = $MODE;
    $key .= '_partial'          if $PARTIAL;
    $key .= '_anchored'         if $ANCHORED;
    $key .= '_captures'         if $CAPTURES;
    $key .= '_case-insensitive' if $CASE_INSENSITIVE;

    return $REGEXES{$key};
}

sub parse_pc {

    croak "parse_pc only works with an anchored regex" unless $ANCHORED;

    Geo::UK::Postcode::Regex->parse(
        shift,
        {   partial            => $PARTIAL          ? 1 : 0,
            strict             => $MODE eq 'lax'    ? 0 : 1,
            valid              => $MODE eq 'valid'  ? 1 : 0,
            'case-insensitive' => $CASE_INSENSITIVE ? 1 : 0,
        }
    );
}

sub extract_pc {

    croak "extract_pc only works with full postcodes" if $PARTIAL;

    Geo::UK::Postcode::Regex->extract(
        shift,
        {   strict             => $MODE eq 'lax'    ? 0 : 1,
            valid              => $MODE eq 'valid'  ? 1 : 0,
            'case-insensitive' => $CASE_INSENSITIVE ? 1 : 0,
        }
    );
}

sub validate_pc {
    my $pc = shift;

    croak "invalid \$MODE $MODE" if $MODE !~ m/^(?:strict|lax|valid)$/;

    my $key = $MODE;

    $key .= '_partial' if $PARTIAL;

    $key .= '_anchored' if $ANCHORED;

    $key .= '_case-insensitive' if $CASE_INSENSITIVE;

    return $pc =~ $REGEXES{$key} ? 1 : 0;
}

1;

__END__

=head1 NAME

Geo::UK::Postcode::Regex::Simple - Simplified interface to Geo::UK::Postcode::Regex

=head1 SYNOPSIS

Localised configuration:

    use Geo::UK::Postcode::Regex::Simple ':all';

    # Set behaviour of regular expression (defaults below)
    local $Geo::UK::Postcode::Regex::Simple::MODE             = 'strict';
    local $Geo::UK::Postcode::Regex::Simple::PARTIAL          = 0;
    local $Geo::UK::Postcode::Regex::Simple::CAPTURES         = 1;
    local $Geo::UK::Postcode::Regex::Simple::ANCHORED         = 1;
    local $Geo::UK::Postcode::Regex::Simple::CASE_INSENSITIVE = 0;

    # Regular expression to match postcodes
    my $re = postcode_re;
    my ( $area, $district, $sector, $unit ) = "AB10 1AA" =~ $re;

    # Get hashref of data parsed from postcode
    my $parsed = parse_pc "AB10 1AA";

    # Extract list of postcodes from text string
    my @extracted = extract_pc $text;

    # Check if string is a correct postcode
    if ( validate_pc $string ) {
        ...
    }

Alternate global configuration:

    use Geo::UK::Postcode::Regex::Simple    #
        ':all'                              #
        -strict                             # or -lax, -valid
        -full                               # or -partial
        -anchored                           # or -unanchored
        -captures                           # or -nocaptures
        -case-sensitive                     # or -case-insensitive
        ;

=head1 DESCRIPTION

Alternative interface to L<Geo::UK::Postcode::Regex>.

=head1 IMPORTANT CHANGES FOR VERSION 0.014

Please note that various bugfixes have changed the following:

=over

=item *

C<extract_pc>, C<parse_pc> now die with invalid import options set

=item *

Unanchored regular expressions no longer match valid postcodes within invalid
ones.

=item *

Unanchored regular expressions in partial mode now can match a valid or strict
outcode with an invalid incode.

=back

Please get in touch if you have any questions.

=head1 CONFIGURATION

=head2 MODE

Sets the regular expressions used to be in one of the following modes:

=over

=item lax

Matches anything that resembles a postcode.

=item strict (default)

Matches only if postcode contains valid characters in the correct
positions.

=item valid

Matches only if the postcode contains valid characters and the outcode exists.

=back

=head2 PARTIAL (default = false )

If true, regular expression returned by C<postcode_re> will match partial
postcodes, at district (outcode) or sector level, e.g. "AB10" or "AB10 1".

=head2 ANCHORED (default = true )

Puts anchors (C<^> and C<$>) around the regular expression returned by
C<postcode_re>.

=head2 CAPTURES (default = true )

Puts capture groups into the regular expression returned by C<postcode_re>. The
matches returned upon a successful match are: area, district, sector and unit
(or outcode, sector and unit for 'valid' mode).

=head2 CASE_INSENSITIVE (default = false)

If false, only parses/matches/extracts postcodes that contain only upper case
characters.

=head1 FUNCTIONS

=head2 postcode_re

    my $re = postcode_re;

Returns a regular expression which will match UK Postcodes. See CONFIGURATION
for details.

=head2 parse_pc

    my $parsed = parse_pc $pc;

Returns a hashref of data extracted from the postcode. See C<parse> in
L<Geo::UK::Postcode::Regex> for more details.

=head2 extract_pc

    my @extracted = extract_pc $test;

Returns a list of postcodes extracted from a text string. See C<extract> in
L<Geo::UK::Postcode::Regex> for more details.

=head2 validate_pc

    if ( validate_pc $pc ) {
        ...
    }

Boolean test for if a string is a (full) postcode or not, according to current
MODE (see CONFIGURATION).

=head1 AUTHOR

Michael Jemmeson E<lt>mjemmeson@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2015- Michael Jemmeson

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

