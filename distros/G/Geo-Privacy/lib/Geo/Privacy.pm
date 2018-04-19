package Geo::Privacy;

=head1 NAME

Geo::Privacy - Information about privacy/GDPR regulations by state

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

All subroutines take an ISO 3166-1 two letter country abbreviation (case
in-sensitive) and return a true/false value.

    use Geo::Privacy qw( is_eea_state is_gdpr_state );

    if ( is_eea_state( 'it' ) ) { say "Yes, Italy is in the EEA" }

    if ( is_gdpr_state( 'de' ) ) { say "GDPR does apply in Germany" }

=cut

use 5.006;
use strict;
use warnings;
use Readonly;
use Exporter::Lite;

our @EXPORT = ();
our @EXPORT_OK = qw( is_eu_state is_gdpr_state is_eea_state has_data_retention_regulations );

Readonly our %EEA_STATES => (
              # Taken from https://en.wikipedia.org/wiki/European_Economic_Area
              # State, Signed, Ratified, Entered into force, Notes
     AT => 1, #Austria     2 May 1992     15 October 1992     1 January 1994     EU member (from 1 January 1995) Acceded to the EEA as an EFTA member[14]
     BE => 1, #Belgium     2 May 1992     9 November 1993     1 January 1994     EU member
     BG => 1, #Bulgaria[15]     25 July 2007     29 February 2008     9 November 2011     EU member
     HR => 1, #Croatia[2]     11 April 2014     24 March 2015[16]     No     EU member (from 1 July 2013) Provisional application from 12 April 2014[2]
     CY => 1, #Cyprus[17]     14 October 2003     30 April 2004     6 December 2005     EU member (The agreement is not applied to Northern Cyprus[Note 2])
     CZ => 1, #Czech Republic[17]     14 October 2003     10 June 2004     6 December 2005     EU member
     DK => 1, #Denmark     2 May 1992     30 December 1992     1 January 1994     EU member
     EU => 1, #European Union     2 May 1992     13 December 1993     1 January 1994     originally as European Economic Community and European Coal and Steel Community
     EE => 1, #Estonia[17]     14 October 2003     13 May 2004     6 December 2005     EU member
     FI => 1, #Finland     2 May 1992     17 December 1992     1 January 1994     EU member (from 1 January 1995) Acceded to the EEA as an EFTA member[14]
     FR => 1, #France     2 May 1992     10 December 1993     1 January 1994     EU member
     DE => 1, #Germany     2 May 1992     23 June 1993     1 January 1994     EU member
     GR => 1, #Greece     2 May 1992     10 September 1993     1 January 1994     EU member
     HU => 1, #Hungary[17]     14 October 2003     26 April 2004     6 December 2005     EU member
     IS => 1, #Iceland     2 May 1992     4 February 1993     1 January 1994     EFTA member
     IE => 1, #Ireland     2 May 1992     29 July 1993     1 January 1994     EU member
     IT => 1, #Italy     2 May 1992     15 November 1993     1 January 1994     EU member
     LV => 1, #Latvia[17]     14 October 2003     4 May 2004     6 December 2005     EU member
     LI => 1, #Liechtenstein     2 May 1992     25 April 1995     1 May 1995     EFTA member
     LT => 1, #Lithuania[17]     14 October 2003     27 April 2004     6 December 2005     EU member
     LU => 1, #Luxembourg     2 May 1992     21 October 1993     1 January 1994     EU member
     MT => 1, #Malta[17]     14 October 2003     5 March 2004     6 December 2005     EU member
     NL => 1, #Netherlands     2 May 1992     31 December 1992     1 January 1994     EU member
     NO => 1, #Norway     2 May 1992     19 November 1992     1 January 1994     EFTA member
     PL => 1, #Poland[17]     14 October 2003     8 October 2004     6 December 2005     EU member
     PT => 1, #Portugal     2 May 1992     9 March 1993     1 January 1994     EU member
     RO => 1, #Romania[15]     25 July 2007     23 May 2008     9 November 2011     EU member
     SK => 1, #Slovakia[17]     14 October 2003     19 March 2004     6 December 2005     EU member
     SI => 1, #Slovenia[17]     14 October 2003     30 June 2005     6 December 2005     EU member
     ES => 1, #Spain     2 May 1992     3 December 1993     1 January 1994     EU member
     SE => 1, #Sweden     2 May 1992     18 December 1992     1 January 1994     EU member (from 1 January 1995) Acceded to the EEA as an EFTA member[14]
     CH => 1, #Switzerland[14]     2 May 1992     No     No     EFTA member EEA ratification rejected in a 1992 referendum Removed as contracting party in 1993 protocol
     UK => 1, #United Kingdom
 );

Readonly our %EU_STATES => (
    # Taken from https://europa.eu/european-union/about-eu/countries/member-countries_en
     AT => 1, #Austria 
     BE => 1, #Belgium
     BG => 1, #Bulgaria
     HR => 1, #Croatia
     CY => 1, #Cyprus
     CZ => 1, #Czech Republic
     DK => 1, #Denmark
     EE => 1, #Estonia
     FI => 1, #Finland
     FR => 1, #France
     DE => 1, #Germany
     GR => 1, #Greece
     HU => 1, #Hungary
     #IS => 1, #Iceland - Not in EU
     IE => 1, #Ireland
     IT => 1, #Italy
     LV => 1, #Latvia
     #LI => 1, #Liechtenstein - Not in EU
     LT => 1, #Lithuania
     LU => 1, #Luxembourg
     MT => 1, #Malta
     NL => 1, #Netherlands
     #NO => 1, #Norway - Not in EU
     PL => 1, #Poland
     PT => 1, #Portugal
     RO => 1, #Romania
     SK => 1, #Slovakia
     SI => 1, #Slovenia
     ES => 1, #Spain
     SE => 1, #Sweden
     #CH => 1, #Switzerland - Not in EU
     UK => 1, #United Kingdom
 );


Readonly our %OTHER_PRIVACY_STATES => (
    AU => 1, # Australia
    CA => 1, # Candada
);


=head1 EXPORT


=head2 is_eu_state

Return true if the specified state is a member of the European Union.

=cut

sub is_eu_state {
    return $EU_STATES{ _normalize_state( @_ ) };
}

=head2 is_gdpr_state

Return true if the specified state is subject to the protections in GDPR.

=cut

sub is_gdpr_state {
    return is_eu_state(@_);
}

=head2 is_eea_state

Return true if the specified state is a member of the European Economic Area

=cut

sub is_eea_state {
    return $EEA_STATES{ _normalize_state( @_ ) };
}

=head2 has_data_retention_regulations

Return true if the specified state is known to have regulations related to the retention of data about its citizens.

Currently, this includes GDPR states as well as Austrailia and Canada.

=cut

sub has_data_retention_regulations {
    my $cc = _normalize_state( @_ );
    return $EEA_STATES{$cc} || $OTHER_PRIVACY_STATES{$cc};
}


sub _normalize_state {
    my ($cc) = @_;
    $cc =~ s/\s//g;
    $cc = uc($cc);
    if ( $cc eq 'GB' ) { return 'UK' }
    return $cc;
}

=head1 AUTHOR

Dan Wright (dan at dwright dot org)

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/dwright/Geo-Privacy/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Dan Wright

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Geo::Privacy
