#
# $Id: PostalAddress.pm,v 1.4 2005/04/30 18:39:28 michel Exp $
#

package Geo::PostalAddress;
use strict;
require 5.00503;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = ();
%EXPORT_TAGS = ();
$VERSION = 0.04; # ExtUtils::MakeMaker will use this.
my $save_version = $VERSION; # Save so I can clean up after Locale::SubCountry

use UNIVERSAL;
use Locale::Country;
use Locale::SubCountry;
use Carp;

if ($save_version ne $VERSION) { # Workaround for Locale::SubCountry lossage
  $Locale::SubCountry::VERSION = $VERSION;
  $VERSION = $save_version;
}

my (%per_country_data, %default_per_country_data);

=head1 NAME

Geo::PostalAddress - Country-specific postal address parsing/formatting

=head1 DESCRIPTION

This module converts postal (snail mail) addresses between an
unstructured country-neutral format (an array of character strings)
and a country-specific format that's hopefully meaningful by postal
authorities, courier/delivery services, residents, ... of that
country for postal address entry. It should handle most countries
out of the box with only minor or technical divergences from
approved bulk-mailing formats; if needed, country-specific code can
be added to make it fully conformant to those formats.

The intended audience for this module is anyone needing to handle
most addresses in a recognizable country-specific format, without
going into the full generality and complexity that UPU standards
would appear to require.

=head1 SYNOPSIS

  use Geo::PostalAddress;

  my $AU_parser = Geo::PostalAddress->new('AU');
  my $format = $AU_parser->format();
  # $format now contains:
  # [['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40], 3,
  #  ['City', 40],
  #  ['State', {NSW => "New South Wales", TAS => "Tasmania",
  #             QLD => "Queensland", SA => "South Australia",
  #             WA  => "Western Australia", VIC => "Victoria",
  #             ACT => "Australian Capital Territory",
  #             NT  => "Northern Territory"}], ['Postcode', 4, qr/^\d\d\d\d$/]]
  # 40 in ['Addr1', 40] is the suggested displayed field width (not the maximum
  # length). 3 means that the next 3 fields should/could be on the same row.
  # ['State', {...}] means an enumerated list is used for this field, with keys
  # being the stored values and values being the labels used for display or
  # selection.
  my $display = $AU_parser->display(["4360 DUKES RD", "KALGOORLIE WA 6430"]);
  # $display now contains:
  # {Addr1 => "4360 DUKES RD", City => "KALGOORLIE",
  #  State => "WA", Postcode => "6430"}

  my $US_parser = Geo::PostalAddress->new('US');
  my $address = {Addr1 => "123 MAGNOLIA ST", City => "HEMPSTEAD",
                 State => "NY", ZIP => "11550­1234"};
  my $result = $US_parser->storage($address);
  unless (ref $result) { carp "Bad postal address: $result.\n"; }

  my $AU_to_US_address_label = $US_parser->label("AU", "MR JOHN DOE", $result);
  # What to print on an address label or on an envelope, if mailing from
  # Australia to the United States.

=head1 METHODS

=head2 new()

C<Geo::PostalAddress-E<gt>new($country)> returns undef, or a blessed
reference to a parser suitable for handling the most common postal address
formats for that country. Depending on the country, this reference may be
blessed into Geo::PostalAddress or into a country-specific subclass.

=cut

sub new {
  my ($class, $code) = @_;
  my $country_class = "Geo::PostalAddress::$code";
  my ($object, $country_new);
  my $instance_data = (exists $per_country_data{$code})
    ? {_country_code => $code, %{$per_country_data{$code}}}
    : {_country_code => $code, %default_per_country_data};

  unless (defined code2country($code, LOCALE_CODE_ALPHA_2)) { return undef; }

  if (exists($Geo::PostalAddress::{"${code}::"})) { # Country class exists
    if (($country_new = $country_class->can("new")) != \&new) { # Has own new()
      # XXX fails if &$country_new calls Geo::PostalAddress->new. MUST FIX.
      $object = $country_new->($country_class, $code);
    } else { # Country class, inherits our new()
      $object = bless $instance_data, $country_class;
    }
  } else { # No country class.
    $object = bless $instance_data, $class;
  }

  return $object;
}

=head2 format

C<$parser-E<gt>format()> returns a reference to an array describing the
(display/input) fields that make a postal address, and gives some hints
about on-screen layout. Each element of the array can be an integer n > 0,
meaning the next n fields should be on the same line if window/screen width
allows it, or a reference to an array describing a field. Each field
description contains the field name and either a maximum length for a text
field or a hash of {stored => display} values for an enumerated field. An
optional regex can also be specified. If present, it should be compatible with
both perl and javascript, so it can be used in both client-side and server-side
programs or modules.

An example for Australia may be:

  [["Addr1", 40], ["Addr2", 40], ["Addr3", 40], ["Addr4", 40], 3, ["City", 40],
   ["State", {NSW => "New South Wales", TAS => "Tasmania", QLD => "Queensland",
              SA => "South Australia", WA => "Western Australia",
              VIC => "Victoria", ACT => "Australian Capital Territory",
              NT => "Northern Territory"}], ["Postcode", 4, qr/^\d\d\d\d$/]]

=cut

sub format {
  my ($self) = @_;

  return $self->{_format};
}

=head2 display

C<$parser-E<gt>display($stored)> converts the postal address in @$stored to a
format suitable for data input and returns a reference to a hash. The keys of
the hash appear as fieldnames in the return value of C<$parser-E<gt>format()>.

If @$stored doesn't contain an address in the country $parser is an instance
of, weird results are nearly certain.

=cut

sub display {
  my ($self, $stored) = @_;
  my %display;
  my $limit = 0;
  my @regex_results; # Cache, 1 per regex (*not* per stored address field)

  foreach my $segment (@{$self->{_s2d_map}}) {
    if ($segment->{StoredRownum} < $limit) {
      $limit = $segment->{StoredRownum};
    }
  }

  $limit += @$stored; # Map positive indexes >= this to empty lines.

  foreach my $segment (@{$self->{_s2d_map}}) {
    my $line
      = ($segment->{StoredRownum} >= $limit)
        ? ""
        : $stored->[$segment->{StoredRownum}];

    if (exists($segment->{StoredColnum})) {
      $line = exists($segment->{StoredCollen})
        ? substr($line, $segment->{StoredColnum}, $segment->{StoredCollen})
        : substr($line, $segment->{StoredColnum});
    }

    if (exists($segment->{StoredRegexnum})) {
      my $renum = $segment->{StoredRegexnum};

      if ($renum > $#regex_results or !defined($regex_results[$renum])) {
        # First time for this regex; cache results.
        my $regex = $self->{_regexes}->[$renum];
        my @fields = $line =~ /$regex/;

        $regex_results[$renum] = \@fields;
      }

      # XXX Complain if not present?
      $line = $regex_results[$renum]->[$segment->{StoredFieldnum}];
    }

   $display{$segment->{DisplayName}} = $line;
  }

  $self->normalize(\%display); # XXX Do something with return value?
  return \%display;
}

=head2 storage

C<$parser-E<gt>storage($display)> makes country-dependent checks against the
postal address in %$display. If it passes all the checks,
C<$parser-E<gt>storage($display)> converts it to a format suitable for storage
and returns a reference to an array. Otherwise,
C<$parser-E<gt>storage($display)> returns a string representing an error
message.

If %$display doesn't contain an address in the country $parser is an instance
of, weird results are nearly certain.

=cut

sub storage {
  my ($self, $display) = @_;
  my (@storage, @storage_bottom);

  foreach my $field (@{$self->{_format}}) {
    if (ref($field) && (@$field >= 3)
        && ($display->{$field->[0]} !~ $field->[2])) {
      return "$field->[0]: missing or incorrect value"; # XXX be more specific?
    }
  }

  if (my $errmsg = $self->normalize($display)) { return $errmsg; }

  foreach my $segment (@{$self->{_d2s_map}}) {
    my $line = $segment->{StoredTemplate};
    my $rownum = $segment->{StoredRownum};

    $line =~ s/\${([^{}]+)}/$display->{$1}/eg;

    if ($rownum < 0) {
      $storage_bottom[1 - $rownum] = $line;
    } else {
      $storage[$rownum] = $line;
    }
  }

  @storage = grep { defined($_) && $_ } @storage;
  @storage_bottom = grep { defined($_) && $_ } @storage_bottom;
  push @storage, reverse @storage_bottom;
  return \@storage;
}

=head2 label

C<$parser-E<gt>label($origin_country, $recipient, $address)> returns a
reference to an array containing an address label suitable for correspondance
from a sender in $origin_country (2-letter ISO 3166 code) to $recipient (can be
a string or an array reference, eg ["Aby's Auto Repair", "Kell Dewclaw"]) at
$address (as returned from C<$parser-E<gt>storage()>) in the country for
$parser.

The default version just tacks on the name of the destination country, if not
the same as the origin country.

=cut

sub label {
  my ($self, $origin_country, $recipient, $address) = @_;
  my @label;

  if (ref $recipient) { @label = @$recipient; } else { @label = ($recipient); }
  push @label, @$address;
  if ($origin_country ne $self->{_country_code}) {
    push @label, code2country($self->{_country_code});
  }

  return \@label;
}

=head2 option

C<$parser-E<gt>option($name [ , $value] )> returns the setting of option $name
for parser $parser, after changing it to $value if specified.

Available options and meaningful values for each option depend on the country
$parser is for.

=cut

sub option {
  my ($self, $name, $value) = @_;

  if (defined $value) { $self->{_options}->{$name} = $value; }
  return $self->{_options}->{$name};
}

=head2 normalize

C<$parser-E<gt>normalize($display)> normalizes the address in %$display by
tweaking unambiguous but technically incorrect elements. It can also, if
needed, check it for validity and return an error message. If no problems were
found, it should return "".

This method is called from within C<storage()> and C<display()>, and users of
this module shouldn't normally need to call it directly. It exists so it can be
overridden in subclasses. The default version does nothing.

=cut

sub normalize {
  return "";
}

=head1 INTERNALS

Unless you plan to add a country or change the format information for a
country, either directly in the base class (this) or as a subclass, you can
safely skip this. (But if you're curious, feel free to read on.)

%per_country_data is a hash using the 2-letter ISO 3166-1 country code as the
key. The value is a hash reference ($hr in the following description) with the
following fields:

=over 4

=item _format

This array reference is actually what C<$parser-E<gt>format()> returns.

Each element can be a number n > 0, hinting that the next n fields should be on
the same line, if the terminal or window width allows it, but otherwise
ignored. Otherwise, it is an array reference describing a single field of the
address, and has the following elements:

=over 4

=item 0

The name of a field. For maximum compatibility with form description languages
(including the forms part of HTML), this should match /^w+$/ in the C locale,
but this module only requires that it not contain {}. The name should be
present in C<map { $_-E<gt>{DisplayName} } @{$hr-E<gt>{_s2d_map}}> (see
_s2d_map below).

=item 1

Can be a number E<gt> 0, indicating the maximum length of a text field, or a
hash of { stored =E<gt> displayed } mappings, indicating an enumerated field.
(Note that in the latter case, the order and layout of the values are left to
the discretion of the user of this module.)

=item 2

An optional validation regex can also be specified. If present, it should be
compatible with both perl and javascript, so it can be used in both client-side
and server-side programs or modules. Note that although most regexes would be
anchored at both ends, this isn't required or enforced.

=back

=item _s2d_map

(storage-to-display map) This is an array of hash references, each describing
how to retrieve the value of one display field from the stored unstructured
text strings. Each element has the following fields:

=over 4

=item StoredRownum

(stored row number) The row in the array of text lines where the field is. That
number is used as a perl-style array index (E<gt>=0 from the start, E<lt> 0
back from the end), except that on any given unstructured address, if there
aren't enough rows to map to both positive and negative indices without
overlap, the positive indices that would actually map to a row overlapping the
region starting with the negative index having the largest absolute value and
going to the end of the array are considered to return "" instead of the actual
row. In other words, using the array of lines qw(eenie meenie minie moe),
indexes -2 0 1 2 3 would return "minie", "eenie", "meenie", "", "" (even though
there is no -1 that would return "moe").

=item StoredColnum

(stored column number) The optional column in the line where the field (or
regex input) starts, from 0 for the first column. If absent, the field (or
regex input) is the whole line, even if StoredCollen is present. Note that
StoredColnum can be negative (with the expected result for the second argument
to L<substr|perldoc/substr>), but if so, there's no special handling, unlike
for StoredRownum.

=item StoredCollen

(stored column length) The optional length of the field (or regex input). If
absent or if StoredColnum is absent, the field (or regex input) extends to the
end of the line. Note that StoredCollen can be negative (with the expected
result for the third argument to L<substr|perldoc/substr>), but if so, there's
no special handling, unlike for StoredRownum.

=item StoredRegexnum

(stored regex number) The optional index of a regular expression in
C<@{$hr-E<gt>{_regexes}}> to be matched against the line (or the substring
selected by StoredColnum and StoredCollen if applicable) to extract the field
value from it. See the description of _regexes below for important restrictions
on regex use.

=item StoredFieldnum

(stored field number) The optional index into the array returned by the regex
matching mentioned above of the data to be returned as the field value. Note
that if StoredRegexnum is present, StoredFieldnum must be present too.

=item DisplayName

(display (field) name) The name of a field in C<@{$hr-E<gt>{_format}}>. This is
also the key used in the record hash returned by C<$parser-E<gt>display()>.

=back

Note that although StoredColnum, StoredCollen, StoredRegexnum, and
StoredFieldnum are all optional, not all combinations make sense. Specifically:

=over 4

=item *

At least one of StoredColnum and StoredRegexnum must be present; if both are,
StoredColnum (and StoredCollen if also present) are used before StoredRegexnum
and StoredFieldnum.

=item *

If StoredCollen is present without StoredColnum, it is ignored.

=item *

If StoredRegexnum is present, StoredFieldnum must be present too; if
StoredFieldnum is present without StoredRegexnum, it is ignored.

=back

=item _s2d_map

(display-to-storage map) This is an array of hash references, each describing
how to generate one line of the unstructured string array used for storage from
the parsed fields used for display. Each element has the following fields:

=over 4

=item StoredTemplate

(stored template) A string containing boilerplate text and field references of
the form ${foo} for field foo (using the field names in _format and _s2d_map).
Currently, there is no way to escape $, {, or } if they're part of a sequence
that could be interpreted as a field reference.

=item StoredRownum

(stored row number) A number that indicates in which row of the unstructured
storage string array this should go. This can be positive, 0, or negative, with
the same intended meaning as for _s2dmap, except than while putting the array
together, it grows in the middle as necessary to accomodate positive indexes.

=back

=item _regexes

(regular expressions) A reference to an array of strings representing regexes,
in any form perl will accept (single-quoted, double-quoted, qr//, etc...) for
use in parsing unstructured storage strings into structured display fields.
Note that each regex is matched at most once in the course of a single
invocation to C<$hr-E<gt>display()>, and its results cached for reuse. This is
true even if a subsequent match would use another string than the first. In
practice, this isn't a problem, as a given regex would normally be applied to
one storage line only. However, if this isn't the case, that regex must be
repeated, each line pointing (through StoredRegexnum) to its own copy.

=back

%default_per_country_data is similar, but for countries with unspecified
address formats. It's a single hash with the same structure as %$hr above.

C<Geo::PostalAddress-E<gt>new()> initializes the object hash with those
fields, and adds a _country_code field that holds the 2-letter code, in case we
need to retrieve other info later.

Note that the above applies to the base class only. Subclasses may use other or
different data, instead of or in addition to this.

=cut

%default_per_country_data = (
  _format => [
    ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40], ['Addr5', 40]
  ],
  _s2d_map => [
    {StoredRownum => 0, DisplayName => 'Addr1'},
    {StoredRownum => 1, DisplayName => 'Addr2'},
    {StoredRownum => 2, DisplayName => 'Addr3'},
    {StoredRownum => 3, DisplayName => 'Addr4'},
    {StoredRownum => 4, DisplayName => 'Addr5'}
  ],
  _d2s_map => [
    {StoredTemplate => '${Addr1}', StoredRownum => 0},
    {StoredTemplate => '${Addr2}', StoredRownum => 1},
    {StoredTemplate => '${Addr3}', StoredRownum => 2},
    {StoredTemplate => '${Addr4}', StoredRownum => 3},
    {StoredTemplate => '${Addr5}', StoredRownum => 4},
  ]
);

# District name, no city or postcode: Albania, Angola, Bahamas, United Arab
# Emirates
# XXX What are districts called in AL & AO? (eg, state/province/county...)
# XXX Andorra subcountries missing from Locale::SubCountry
# XXX Aruba subcountries missing from Locale::SubCountry
# XXX Bhutan subcountries missing from Locale::SubCountry or not the right ones
# XXX Grenada districts missing from Locale::SubCountry (also, West Indies?)
# XXX Nauru (NR) missing from Locale::SubCountry
foreach my $spec ((['AE', 'Emirate'], ['AL', 'District'], ['AO', 'District'],
                   ['BS', 'Island'])) {
  my ($code, $district) = @$spec;
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  my $subctry = Locale::SubCountry->new($code);
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40],
      [$district, { map { $_ => $_ } $subctry->all_full_names() } ]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -1, DisplayName => $district}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => "\$\{$district\}", StoredRownum => -1}
    ]
  };
}

# Postcode (and postcode prefix) left of city, no district: Algeria, Andorra,
# Argentina, Armenia, Austria, Azerbaijan, Belarus, Belgium, Bosnia and
# Herzegovina, Bulgaria, China, Costa Rica, Croatia, Cuba, Cyprus, Czech
# Republic, Denmark, Estonia, Ethiopia, Faroe, Finland, France, Gabon, Georgia,
# Germany, Guatemala, Guinea Bissau, Haiti, Iceland, Iran, Israel, Kuwait,
# Kyrgyzstan, Lao, Liberia, Liechtenstein, Lithuania, Luxembourg, Madagascar,
# Moldova, Monaco, Morocco, New Caledonia, Niger, Norway, Paraguay,
# Philippines, Romania, Russian Federation, San Marino, Senegal, Serbia and
# Montenegro, Slovenia, Spain, Tajikistan, Former Yugoslav Republic of
# Macedonia, Tunisia, Turkey, Turkmenistan, Vatican, Zambia.
# XXX Aruba may be here as part of the Netherlands.
# XXX I require Andorra postcodes to start with AD (uppercase). A better
# approach may be to make them optional and have normalize add them if needed.
# XXX Armenia may need 6-digit postcodes, not 4.
# XXX Austria may not require, or forbid, the A- postcode prefix.
# XXX Azerbaijan may need 6-digit postcodes, not 4.
# XXX Belarus addresses used to be upside down, but no longer. Thanks to
# LeiaCat for the information.
# XXX Belgium may not require, or forbid, the B- postcode prefix.
# XXX China postcodes may be after city, not before.
# XXX Croatia may use county code as first 2 digits of postcode.
# XXX Cuba may use county/district code as first 2 digits of postcode, but the
# district codes Locale::SubCountry gives are inconsistent with the sample
# addresses.
# XXX Cyprus may need a CY- postcode prefix.
# XXX Denmark may want a DK- postcode prefix.
# XXX Estonia may want EE- postcode prefix. Also, after postcode is city or
# region, but Locale::SubCountry only has regions, no cities.
# XXX Finland wants a different postcode prefix and an extra line for addresses
# in the Åland Islands. Forget about it for now?
# XXX I require Faroe postcodes to start with AD (uppercase). A better approach
# may be to make them optional and have normalize add them if needed.
# XXX France apparently no longer uses numeric codes for its outlying bits, but
# I'm not sure which (if any) alpha codes are valid. Note that I don't
# uppercase the 2A... and 2B... postcodes used for Corsica. Also, may want a F-
# or FR- postcode prefix.
# XXX French Guiana is here, as part of France.
# XXX Ditto for French Polynesia, except that it may want its own country name.
# If it does, handle with normalize(). (Can't make it its own country, even
# though it has an ISO 3166-1 entry, as it's missing from Locale::Country and
# Locale::SubCountry.)
# XXX Georgia may want 6-digit postcode, not 4.
# XXX Germany doesn't want a postcode prefix anymore, apparently.
# XXX Greenland may be part of Denmark, or it may use the same format but with
# its own country name. Go for the former.
# XXX Guadeloupe is here, as part of France.
# XXX I require Haiti postcodes to start with HT (uppercase). A better approach
# may be to make them optional and have normalize() add them if needed. Also,
# the numeric part may be further constrained, but I don't have a complete list
# of postcodes.
# XXX Iceland postcodes may be further constrained (first digit 0-8) and may
# need an IS- postcode prefix.
# XXX Israel may use a IL- postcode prefix.
# XXX Kyrgyzstan seems to want addresses upside down, with recipient just above
# country. If it does, handle it with label() for now. Not ideal.
# XXX Liechtenstein may have the postcode right of city, not left. Also, using
# the Switzerland/CH format, with Liechtenstein/FL (not LI?) instead.
# XXX Luxembourg may use a L- or LU- postcode prefix.
# XXX Mayotte is here, as part of France.
# XXX Macedonia postcodes may be 5 digits with a MK- prefix, not 4 digits and
# prefixless.
# XXX Monaco postcodes may be more constrained than 5 digits. Also, it may use
# a MC- postcode prefix.
# XXX Martinique is here, as part of France.
# XXX New Caledonia is just like France, except with its own country name and
# postcodes starting in 988.
# XXX Norway may use a N- or NO- postcode prefix.
# XXX Philippines may be using district/province instead of city, or either
# district/province or city, but I'm not sure which, and neither Manila nor
# Metro Manila are in the Locale::SubCountry.pm list, so pretend it's a city.
# XXX Réunion is here, as part of France.
# XXX Russian Federation prefers addresses upside down for local use, but can
# handle the more common format in international mail. Also, it seems to want
# postcodes under the country name, but we don't do that. Put it left of the
# city for now, although below city (and above country) may be a better place.
# Saint Pierre and Miquelon is (are?) here, as part of France.
# XXX San Marino may have a single city, as Singapore. Also, all postcodes
# start with 4789.
# XXX Spain may want the province name between () after the city name for some
# cities. Leave it here until I know more.
# XXX Svalbard and Jan Mayen Island may be here, as part of Norway.
# XXX Switzerland may want a CH postcode prefix. Also, ambiguous cities may
# need district (canton) code postfixed. Let users enter it as part of city if
# needed (same as post office number).
# XXX Tajikistan may have a district code before the postcode, but the list in
# Locale::SubCountry looks incomplete.
# XXX Tunisia may use a TN- postcode prefix.
# XXX Turkmenistan wants addresses in the postcode+city, country, name, street
# order?
# XXX Vatican actually has a single postcode. (It's part of the Italian postal
# system, but doesn't has a province appended, and has its own country name.)
# Wallis and Futuna is here as part of France.
foreach my $spec
    ((['DZ', 5, qr/^(0[1-9]|[1-3][0-9]|4[0-8])\d{3}$/, ''],
      ['FR', 5, qr/^([02][1-9]|[13-8][0-9]|2[AB]|9[0-578])\d{3}$/, ''],
      ['AD', 5, qr/^AD\d{3}$/, ''],      ['AM', 4, qr/^\d{4}$/, ''],
      ['AR', 8, qr/^\w\d{4}\w{3}$/, ''], ['AT', 4, qr/^\d{4}$/, 'A-'],
      ['AZ', 4, qr/^\d{4}$/, 'AZ'],      ['BY', 6, qr/^\d{6}$/, ''],
      ['BE', 4, qr/^\d{4}$/, 'B-'],      ['BA', 5, qr/^\d{5}$/, ''],
      ['BG', 4, qr/^\d{4}$/, 'BG-'],     ['CN', 6, qr/^\d{6}$/, ''],
      ['CR', 4, qr/^\d{4}$/, ''],        ['HR', 5, qr/^\d{5}$/, 'HR-'],
      ['CU', 5, qr/^\d{5}$/, 'CP '],     ['CY', 4, qr/^\d{4}$/, ''],
      ['DK', 4, qr/^\d{4}$/, ''],        ['EE', 5, qr/^\d{5}$/, ''],
      ['ET', 4, qr/^\d{4}$/, ''],        ['FI', 5, qr/^\d{5}$/, 'FI-'],
      ['FO', 5, qr/^FO\d{3}$/, ''],      ['GA', 2, qr/^\d\d$/, ''],
      ['GE', 4, qr/^\d{4}$/, ''],        ['DE', 5, qr/^\d{5}$/, ''],
      ['GT', 5, qr/^\d{5}$/, ''],        ['GW', 4, qr/^\d{4}$/, ''],
      ['HT', 6, qr/^HT\d{4}$/, ''],      ['IS', 3, qr/^\d{3}$/, ''],
      ['IR', 10, qr/^\d{10}$/, ''],      ['IL', 5, qr/^\d{5}$/, ''],
      ['KW', 5, qr/^\d{5}$/, ''],        ['KG', 6, qr/^\d{6}$/, ''],
      ['LA', 5, qr/^\d{5}$/, ''],        ['LI', 4, qr/^\d{4}$/, 'FL-'],
      ['LR', 4, qr/^\d{4}$/, ''],        ['LT', 5, qr/^\d{5}$/, 'LT-'],
      ['LU', 4, qr/^\d{4}$/, 'L-'],      ['MG', 3, qr/^\d{3}$/, ''],
      ['MD', 5, qr/^\d{5}$/, 'MD-'],     ['MC', 5, qr/^\d{5}$/, ''],
      ['MA', 5, qr/^\d{5}$/, ''],        ['NC', 5, qr/^988\d\d$/, ''],
      ['NE', 4, qr/^\d{4}$/, ''],        ['NO', 4, qr/^\d{4}$/, ''],
      ['PH', 4, qr/^\d{4}$/, ''],        ['PY', 4, qr/^[1-9]\d{3}$/, ''],
      ['RO', 6, qr/^\d{6}$/, ''],        ['RU', 6, qr/^\d{6}$/, ''],
      ['SM', 5, qr/^4789\d$/, ''],       ['SN', 5, qr/^\d{5}$/, ''],
      ['CS', 5, qr/^\d{5}$/, ''],        ['SI', 4, qr/^\d{4}$/, ''],
      ['ES', 5, qr/^\d{5}$/, ''],        ['CH', 4, qr/^\d{4}$/, ''],
      ['TJ', 6, qr/^\d{6}$/, ''],        ['MK', 4, qr/^\d{4}$/, ''],
      ['TN', 4, qr/^\d{4}$/, ''],        ['TR', 5, qr/^\d{5}$/, ''],
      ['TM', 6, qr/^\d{6}$/, ''],        ['VA', 5, qr/^00120$/, ''],
      ['ZM', 5, qr/^\d{5}$/, ''])) {
  my ($code, $postcode_len, $postcode_re, $postcode_pfx) = @$spec;
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40], 2,
      ['Postcode', $postcode_len, $postcode_re], ['City', 40],
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -1, DisplayName => 'Postcode',
        StoredColnum => length($postcode_pfx), StoredCollen => $postcode_len},
      {StoredRownum => -1, DisplayName => 'City',
        StoredColnum => length($postcode_pfx) + $postcode_len + 1}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => "$postcode_pfx\$\{Postcode\} \$\{City\}",
        StoredRownum => -1}
    ]
  };
}

# Variable length postcode (and postcode prefix) left of city, no district:
# Chile, Czech Republic, Dominican Republic, Greece, Guinea, Netherlands,
# Poland, Portugal, Slovakia, Sweden
# XXX Czech Republic wants a space after the 3rd digit of the postcode. Also,
# it may want CZ- as a postcode prefix.
# XXX Dominican Republic wants a - after the 5th digit of the postcode.
# XXX Greece doesn't want a postcode prefix anymore, apparently.
# XXX Guinea postcodes include a PO box. 12 leaves room for 5-digits PO box #s.
# Also, I don't try to normalize postcodes.
# XXX Netherlands may want a NL- postcode prefix.
# XXX Netherlands Antilles are here, as part of the Netherlands.
foreach my $spec
    ((['CL', 8, qr/^\d{3}[-\s]*\d{4}$/, '${Postcode} ${City}',
       qr/^(\d{3}[-\s]?\d{4})\s+(.+)$/],
      ['CZ', 6, qr/^\d\d\s?\d{3}$/, '${Postcode}  ${City}',
       qr/^(\d{3}\s*\d\d)\s+(.+)$/],
      ['DO', 10, qr/^\d{5}[-\s]*\d{4}$/, '${Postcode} ${City}',
       qr/^(\d{5}[-\s]*\d{4})\s+(.+)$/],
      ['GR', 6, qr/^\d{3}\s*\d\d$/, '${Postcode} ${City}',
       qr/^(\d{3}\s*\d\d)\s+(.+)$/],
      ['GN', 12, qr/^[0-4]\d\d\s*BP\s*\d+$/i, '${Postcode} ${City}',
       qr/^([0-4]\d\d\s*BP\s*\d+)\s+(.+)$/i],
      ['NL', 7, qr/^\d{4}\s?w\w$/, '${Postcode} ${City}',
       qr/^(\d{4}\s?w\w)\s+(.+)$/],
      ['PL', 6, qr/^\d{3}-?\d\d$/, '${Postcode} ${City}',
       qr/^(\d{3}-?\d\d)\s+(.+)$/],
      ['PT', 8, qr/^\d{4}-?\d{3}$/, '${Postcode} ${City}',
       qr/^(\d{4}-?\d{3})\s+(.+)$/],
      ['SK', 6, qr/^\d{3}\s*\d\d$/, '${Postcode}  ${City}',
       qr/^(\d{3}-?\d\d)\s+(.+)$/],
      ['SE', 6, qr/^\d{3}\s*\d\d$/, 'SE-${Postcode} ${City}',
       qr/^(?i:SE-)?(\d{3}[\s-]?\d\d)\s+(.+)$/])) {
  my ($code, $postcode_len, $postcode_re, $pc_layout, $pc_re) = @$spec;
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40], 2,
      ['Postcode', $postcode_len, $postcode_re], ['City', 40]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -1, DisplayName => 'Postcode',
        StoredRegexnum => 0, StoredFieldnum => 0},
      {StoredRownum => -1, DisplayName => 'City',
        StoredRegexnum => 0, StoredFieldnum => 1}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => $pc_layout, StoredRownum => -1}
    ],
    _regexes => [ $pc_re ]
  };
}

# Postcode right of city, no district: Bermuda, Bahrain, Cambodia, India,
# Indonesia, Jordan, Republic of Korea (aka South Korea), Latvia, Lebanon,
# Lesotho, Maldives, Malta, Mongolia, Myanmar, Nepal, New Zealand, Pakistan,
# Saudi Arabia, Taiwan.
# XXX Cook Islands may be here too as part of New Zealand.
# XXX Note that state (code or name) is optional (and almost never used) in
# India addresses provided that postcode is present. (thanks to Martin DeMello
# for the information.)
# XXX Republic of Korea may need region/city (in list) instead of city name,
# and its postal authority suggests adding "Seoul" to the city name on
# international mail, no matter what the destination, to avoid misrouting to
# North Korea. for now, treat it all like a big unstructured city field.
# XXX Mongolia wants postcodes right of country, not city, and some cities at
# least have a delivery/route code after the city. OTOH, anything next to the
# country name is a bad idea. Leave the postcode right of the city for now.
# XXX New Zealand postcodes are optional, except for bulk mailers. This means
# that many people probably don't know their postcode. Asking for it anyway
# doesn't hurt.
# XXX Niue may be here as part of New Zealand.
# XXX Saudi Arabia addresses use separate formats for Latin and Arabic scripts.
# XXX Tokelau may be here as part of New Zealand.
# XXX Not sure of the format for Taiwan postcodes: may be 3 digits, 5 digits,
# or 5 digits with a - after the 3rd.
foreach my $spec
    ((['BH', 4, qr/^([2-9]|1[0-2]?)\d\d$/, 
       qr/^(.+)\s+((?:[2-9]|1[0-2]?)\d\d)$/, ' '],
      ['BM', 5, qr/^\w\w\s*(\d\d|\w\w)$/,
       qr/^(.+)\s+(\w\w\s*(?:\d\d|\w\w))$/, ' '],
      ['KH', 5, qr/^\d{5}$/, qr/^(.+)\s+(\d{5})$/, ' '],
      ['IN', 6,
       qr/^(1[1-9]|2[0-8]|[35][0-36-9]|34|[47][0-9]|6[0-47-9]|8[0-5])\d{4}$/,
       qr/^(.+)(?:\s+|\s*-\s*)(\d{6})$/, '-'],
      ['ID', 5, qr/^\d{5}$/, qr/^(.+)\s+(\d{5})$/, ' '],
      ['JO', 5, qr/^\d{5}$/, qr/^(.+)\s+(\d{5})$/, ' '],
      ['KR', 7, qr/^\d{3}-?\d{3}$/, qr/^(.+)\s+(\d{3}-?\d{3})$/, ' '],
      ['LV', 4, qr/^\d{4}$/, qr/^(.+?),?\s*(?:LV\s*-\s*)?(\d{4})$/, ', LV-'],
      ['LB', 9, qr/^\d{4}\s*\d{4}?$/, qr/^(.+?)\s+(\d{4}\s*\d{4}?)$/, ' '],
      ['LS', 3, qr/^\d{3}$/, qr/^(.+)\s+(\d{3})$/, ' '],
      ['MV', 5, qr/^\d\d-?\d\d$/, qr/^(.+)\s+(\d\d-?\d\d)$/, ' '],
      ['MT', 7, qr/^\w{3}\s*\d{2,3}$/, qr/^(.+)\s+(\w{3}\s*\d{2,3})$/, ' '],
      ['MN', 6, qr/^\d{6}$/, qr/^(.+)\s+(\d{6})$/, ' '],
      ['MM', 5, qr/^(0[1-9]|1[0-4])\d{3}$/, qr/^(.+)(?:,\s*|\s+)(\d{5})$/, ' '],
      ['NP', 5, qr/^\d{5}$/, qr/^(.+)\s+(\d{5})$/, ' '],
      ['NZ', 4, qr/^(\d{4})?$/, qr/^(.+?)(?:\s+(\d{4}))?$/, ' '],
      ['PK', 5, qr/^\d{5}$/, qr/^(.+)(?:\s*-\s*|\s+)(\d{5})$/, ' '],
      ['SA', 5, qr/^\d{5}$/, qr/^(.+)\s+(\d{5})$/, ' '],
      ['VN', 6, qr/^\d{6}$/, qr/^(.+)\s+(\d{6})$/, ' '],
      ['TW', 6, qr/^\d{3}(-?\d{2})?$/,
       qr/^(.+)(?:,\s*|\s+)\d{3}(?:-?\d{2})?$/, ' '])) {
  my ($code, $postcode_len, $postcode_re, $cp_re, $postcode_prefix) = @$spec;
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40], 2,
      ['City', 40], ['Postcode', $postcode_len, $postcode_re]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -1, DisplayName => 'City',
        StoredRegexnum => 0, StoredFieldnum => 0},
      {StoredRownum => -1, DisplayName => 'Postcode',
        StoredRegexnum => 0, StoredFieldnum => 1}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => "\$\{City\}$postcode_prefix\$\{Postcode\}",
        StoredRownum => -1}
    ],
    _regexes => [ $cp_re ]
  };
}

# Postcode left of city, district name below: Cape Verde, El Salvador,
# Mozambique
# XXX Cape Verde seems to be missing an island in Locale::SubCountry.pm.
foreach my $spec
    ((['CV', 'Island'], ['SV', 'Department'], ['MZ', 'Province'])) {
  my ($code, $dname) = @$spec;
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  my $subctry = Locale::SubCountry->new($code);
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40], 2,
      ['Postcode', 4, qr/^\d{4}$/], ['City', 40],
      [$dname, { map { $_ => $_ } $subctry->all_full_names() } ]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -2, DisplayName => 'Postcode',
        StoredColnum => 0, StoredCollen => 4},
      {StoredRownum => -2, DisplayName => 'City', StoredColnum => 5},
      {StoredRownum => -1, DisplayName => $dname}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => '${Postcode} ${City}', StoredRownum => -2},
      {StoredTemplate => "\$\{$dname\}", StoredRownum => -1}
    ]
  };
}

# Postcode right of city, district name below: Nigeria
foreach my $code (qw(NG)) {
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  my $subctry = Locale::SubCountry->new($code);
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40], 2,
      ['City', 40], ['Postcode', 6, qr/^\d{6}$/],
      ['State', { map { $_ => $_ } $subctry->all_full_names() } ]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -2, DisplayName => 'City',
        StoredRegexnum => 0, StoredFieldnum => 0},
      {StoredRownum => -2, DisplayName => 'Postcode',
        StoredRegexnum => 0, StoredFieldnum => 1},
      {StoredRownum => -1, DisplayName => 'State'}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => '${City} ${Postcode}', StoredRownum => -2},
      {StoredTemplate => '${State}', StoredRownum => -1}
    ],
    _regexes => [ qr/^(.+)\s+(\d{6})$/ ]
  };
}

# City and district name each on a line by itself, no postcode: Ireland,
# Kiribati, Panama, Solomon Islands
# XXX Ireland district (county) is optional (forbidden?) if same as city, and
# prefixed with 'CO ' is present. If it's forbidden, not just optional, let
# normalize() handle it. Also, Dublin needs a numeric suffix.
# XXX Kiribati district (island) list may be incomplete or incorrect.
# XXX Panama may use district only, not city.
# XXX Seychelles may be here too, but they're missing from Locale::SubCountry.
# XXX Solomon Islands district (province) list may be incomplete or incorrect.
foreach my $spec
    ((['IE', 'County', 'CO '], ['KI', 'Island', ''], ['PA', 'Province', ''],
      ['SB', 'Province', ''])) {
  my ($code, $dname, $dpfx) = @$spec;
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  my $subctry = Locale::SubCountry->new($code);
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40], ['City', 40],
      [$dname, { map { $_ => $_ } $subctry->all_full_names() } ]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -2, DisplayName => 'City'},
      {StoredRownum => -1, DisplayName => $dname,
        StoredColnum => length($dpfx)}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => '${City}', StoredRownum => -2},
      {StoredTemplate => "$dpfx\$\{$dname\}", StoredRownum => -1}
    ]
  };
}

# City, district code/name, postcode in some order all on same line: Australia,
# Canada, Italy, Japan, Malaysia, Mexico, Papua New Guinea, Somalia, United
# States, Venezuela
# DamienPS explained something (I forgot what) about Australian postcodes.
# XXX American Samoa may be here as part of the US.
# XXX Cocos (Keeling) Islands may be here, as part of Australia.
# XXX Christmas Island may be here, as part of Australia.
# XXX Canadian postcodes want uppercase letters and 1 space after 3rd position.
# XXX Federated States of Micronesia may be here as part of the US.
# XXX Guam may be here as part of the US.
# XXX Heard Island and McDonald Islands may be here as part of Australia.
# XXX Honduras districts are missing from Locale::SubCountry
# XXX Thanks to Renée for splainin what Japan adresses are like. Also, this
# assumes city and prefecture names don't contain spaces. Also, there may be a
# trend toward moving the postcode to its own line below city and prefecture,
# and we leave the - insertion after the 3rd postcode digit to normalize(), if
# it's really necessary. (Since addresses in Roman script are still sorted by
# hand according to the UPU page about Japan, I doubt it is.)
# XXX Malaysia doesn't use the names of the federal territories for routing,
# and they appear optional.
# XXX Marshall Islands may be here as part of the US.
# XXX Mariana Islands may be here as part of the US.
# XXX Mexico addresses may use state name, not code. Also, on-screen field
# order of addresses doesn't match natural/stored.
# XXX Norfolk Island may be here as part of Australia.
# XXX Puerto Rico may be here as part of the US.
# XXX United States definition in Locale::SubCountry.pm is missing AA/AE/AP
# entries for APO/FPO.
# XXX Venezuela definition in Locale::SubCountry.pm may be missing some states.
# XXX US Virgin Islands may be here as part of the US.
foreach my $spec
    ((['AU', 'State', 'Postcode', 4, qr/^\d{4}$/,
       '${City} ${State} ${Postcode}',
       0, 0, 1, 2, qr/^(.+),?\s+(\w{2,3})\s+(\d{4})$/],
      ['CA', 'Province', 'Postcode', 7, qr/^\w\d\w\s*\d\w\d$/,
       '${City} ${Province}  ${Postcode}', 0, 0, 1, 2,
       qr/^(.+)\s+(\w\w)\s+(\w\d\w\s*\d\w\d)$/],
      ['IT', 'Province', 'Postcode', 5, qr/^\d{5}$/,
       '${Postcode}-${City} ${Province}',
       0, 1, 2, 0, qr/^(\d{5})(?:\s*-\s*|\s+)(.+?)(?:\s+(\w\w))?$/],
      ['JP', 'Prefecture', 'Postcode', 8, qr/^\d{3}-?\d{4}$/,
       '${City} ${Prefecture} ${Postcode}', 1, 0, 1, 2,
       qr/^(\S+)\s+(\S+)\s+(\d\d\d-?\d\d\d\d)$/],
      ['MY', 'State', 'Postcode', 5, qr/^\d{5}$/,
       '${Postcode} ${City}, ${State}',
       1, 1, 2, 0, qr/^(\d{5})\s+(.+),\s*(\w+)$/],
      ['MX', 'State', 'Postcode', 5, qr/^\d{5}$/,
       '${Postcode} ${City}, ${State}',
       0, 1, 2, 0, qr/^(\d{5})\s+(.+),\s*(\w+)$/],
      ['PG', 'Province', 'Postcode', 3, qr/^\d{3}$/,
       '${City} ${Postcode} ${Province}',
       0, 0, 2, 1, qr/^(.+)\s+(\d{3})\s+(\w{3})$/],
      ['SO', 'Region', 'Postcode', 5, qr/^\d{5}$/,
       '${City}, ${State}  ${Postcode}',
       0, 0, 1, 2, qr/^(.+),?\s+(\w{2})\s+(\d{5})$/],
      ['US', 'State', 'ZIP', 10, qr/^\d{5}(-\d{4})?$/,
       '${City}, ${State}  ${ZIP}', 0, 0, 1, 2,
       qr/^(.+),?\s+(\w{2})\s+(\d{5}(?:-\d{4})?)$/],
      ['VE', 'State', 'Postcode', 4, qr/^\d{4}$/,
       '${City}, ${Postcode} ${State}',
       1, 0, 2, 1, qr/^(.+?)\s+(\d{4})\s*,?\s+(.+)$/])) {
  my ($code, $district, $postcode, $pc_length, $pc_re, $cdp_layout, $use_dname,
      $city_fn, $district_fn, $pc_fn, $cdp_re) = @$spec;
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  my $subctry = Locale::SubCountry->new($code);
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40], 3,
      ['City', 40],
      [$district, ($use_dname ? { map { $_ => $_ } $subctry->all_full_names() }
                              : {$subctry->code_full_name_hash})],
      [$postcode, $pc_length, $pc_re]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -1, DisplayName => 'City',
        StoredRegexnum => 0, StoredFieldnum => $city_fn},
      {StoredRownum => -1, DisplayName => $district,
        StoredRegexnum => 0, StoredFieldnum => $district_fn},
      {StoredRownum => -1, DisplayName => $postcode,
        StoredRegexnum => 0, StoredFieldnum => $pc_fn},
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => $cdp_layout, StoredRownum => -1}
    ],
    _regexes => [ $cdp_re ]
  };
}

# City and district code (with postfix) on 1 line, then postcode alone below:
# Brazil
# XXX Brazil may need a "Brazil" suffix after some or all states.
foreach my $code (qw(BR)) {
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  my $subctry = Locale::SubCountry->new($code);
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40], 2,
      ['City', 40], ['State', {$subctry->code_full_name_hash}],
      ['Postcode', 9, qr/^\d\d\d\d\d-?\d\d\d$/]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -2, DisplayName => 'City',
        StoredRegexnum => 0, StoredFieldnum => 0},
      {StoredRownum => -2, DisplayName => 'State',
        StoredRegexnum => 0, StoredFieldnum => 1},
      {StoredRownum => -1, DisplayName => 'Postcode'}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => '${City}-${State}', StoredRownum => -2},
      {StoredTemplate => '${Postcode}', StoredRownum => -1}
    ],
    _regexes => [ qr/^(.+?)(?:\s*-\s*|\s+)(\w\w)$/ ]
  };
}

# Postcode alone, then city and district below: Nicaragua
# XXX Nicaragua postcodes may be extended from 7 to 11 digits in the future.
foreach my $code (qw(NI)) {
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  my $subctry = Locale::SubCountry->new($code);
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40],
      ['Postcode', 9, qr/^\d{3}-?\d{3}-?\d$/], 2, ['City', 40],
      ['Department', { map { $_ => $_ } $subctry->all_full_names() } ]
     ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -2, DisplayName => 'Postcode'},
      {StoredRownum => -1, DisplayName => 'City',
        StoredRegexnum => 0, StoredFieldnum => 0},
      {StoredRownum => -1, DisplayName => 'State',
        StoredRegexnum => 0, StoredFieldnum => 1}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => '${Postcode}', StoredRownum => -2},
      {StoredTemplate => '${City}, ${State}', StoredRownum => -1}
    ],
    _regexes => [ qr/^(.+),\s*(.+)$/ ]
  };
}

# City and district name on same line, no postcode: Colombia
# XXX Information on Colombia is inconsistent: does it use city+district, or
# city only?
foreach my $code (qw(CO)) {
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  my $subctry = Locale::SubCountry->new($code);
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40], 2,
      ['City', 40],
      ['Department', { map { $_ => $_ } $subctry->all_full_names() } ]
     ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -1, DisplayName => 'City',
        StoredRegexnum => 0, StoredFieldnum => 0},
      {StoredRownum => -1, DisplayName => 'Department',
        StoredRegexnum => 0, StoredFieldnum => 1}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => '${City}-${Department}', StoredRownum => -1}
    ],
    _regexes => [ qr/^(.+?)(?:\s*[-,]\s*(.*))?$/ ]
  };
}

# District name and postal code each on a line by itself: Egypt
# XXX Kazakhstan would sort of be here too, but Locale::SubCountry seems to be
# missing stuff.
foreach my $code (qw(EG)) {
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  my $subctry = Locale::SubCountry->new($code);
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40],
      ['Governorate', { map { $_ => $_ } $subctry->all_full_names() } ],
      ['Postcode', 5, qr/^\d\d\d\d\d$/]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -2, DisplayName => 'Governorate'},
      {StoredRownum => -1, DisplayName => 'Postcode'}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => '${Governorate}', StoredRownum => -2},
      {StoredTemplate => '${Postcode}', StoredRownum => -1}
    ]
  };
}

# City, name of district, and postcode each on a line by itself: Ukraine,
# United Kingdom (not Great Britain, dammit!)
# XXX Anguilla may be here as part of the UK.
# XXX Antigua and Barbuda may be here as part of the UK.
# XXX British Virgin Islands may be here as part of the UK.
# XXX British Indian Ocean Territory would be here as part of UK, but the
# postcode given for it (BBND 1ZZ) doesn't match the pattern.
# XXX Ditto for British Antarctic territory and BIQQ 1ZZ.
# XXX Ditto for Falkland Islands and FIQQ 1ZZ.
# XXX Ditto for Gibraltar and (I think) GIR 0AA.
# XXX Guernsey may be here as part of the UK.
# XXX Isle of Man may be here as part of the UK, or it may need its own country
# name. Go with the former.
# XXX Jersey may be here as part of the UK.
# XXX Monserrat may be here as part of the UK.
# XXX Pitcairn, Henderson, Ducie, and Oeno Island would be here as part of UK,
# but the postcode given for it (PCRN 1ZZ) doesn't match the pattern.
# XXX South Georgia and the South Sandwich Island: ditto (SIQQ 1ZZ)
# XXX Tristan Da Cunha: ditto (TDCU 1ZZ), and the rest of the example address
# format is weird: "Via Capetown"?? Also, are Saint Helena and Tristan Da Cunha
# the same?
# XXX Turks and Caicos: ditto (TECA 1ZZ).
# XXX Ukraine addresses may not need districts in some cases (large cities?).
# XXX UK addresses come in 2 formats: postcode below city/county, and postcode
# on the right. Usually, postcode on the right is for storage/reference, and
# postcode below for mailing. However, I use postcode below exclusively. If
# you're curious why, just look at the postcode regexp. (thanks to Ailbhe for
# the clarification.) Also: as always, I don't enforce separators or upper case
# in postal codes. Plus, it's not obvious that the county is optional unless
# the user groks UK addresses.
# XXX Uzbekistan addresses may not need districts in some cases (large
# cities?). Also, it may want postcode below country. Pretend it doesn't.
foreach my $spec
    ((['GB', 'County', 8, qr/^\w\w?\d[\w\d]?\s*\d\w\w$/],
      ['UA', 'Region', 5, qr/^\d{5}$/], ['UZ', 'Region', 6, qr/^\d{6}$/])) {
  my ($code, $dname, $pc_len, $pc_re) = @$spec;
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  my $subctry = Locale::SubCountry->new($code);
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40], ['City', 40],
      [$dname, { map { $_ => $_ } $subctry->all_full_names() }],
      ['Postcode', $pc_len, $pc_re]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -3, DisplayName => 'City'},
      {StoredRownum => -2, DisplayName => $dname},
      {StoredRownum => -1, DisplayName => 'Postcode'}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => '${City}', StoredRownum => -3},
      {StoredTemplate => "\$\{$dname\}", StoredRownum => -2},
      {StoredTemplate => '${Postcode}', StoredRownum => -1}
    ]
  };
}

# Postcode on a line by itself, then city: Ecuador, Sudan, Uruguay
# XXX Note that I don't uppercase the letters in Ecuador postcodes
# XXX Uruguay may want the district name (and country) next to the city.
foreach my $spec ((['EC', 6, qr/^\w\d{4}\w$/], ['SD', 5, qr/^\d{5}$/],
                   ['UY', 5, qr/^\d{5}$/])) {
  my ($code, $pc_len, $pc_re) = @$spec;
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40],
      ['Postcode', $pc_len, $pc_re], ['City', 40]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -2, DisplayName => 'Postcode'},
      {StoredRownum => -1, DisplayName => 'City'}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => '${Postcode}', StoredRownum => -2},
      {StoredTemplate => '${City}', StoredRownum => -1}
    ]
  };
}

# Postcode and prefix on a line by itself under city: Iraq, Kenya, Oman, South
# Africa, Sri Lanka, Swaziland
# XXX Ascension would go there too, but it's not in ISO 3166.
# XXX Iraq may want city, district instead.
# XXX Oman examples show postcode above city, not below.
# XXX Sri Lanka examples show postcode below city, but text says it should be
# above. Assume below.
foreach my $spec
    ((['IQ', 5, qr/^\d{5}$/, ''], ['KE', 5, qr/^\d{5}$/, ''],
      ['OM', 3, qr/^\d{3}$/, ''],
      ['ZA', 4, qr/^\d{4}$/, ''], ['LK', 5, qr/^\d{5}$/, ''],
      ['SZ', 4, qr/^[HhLlMmSs]\d{3}$/, ''])) {
  my ($code, $pc_length, $pc_re, $pc_prefix) = @$spec;
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40],
      ['City', 40], ['Postcode', $pc_length, $pc_re]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -2, DisplayName => 'City'},
      {StoredRownum => -1, DisplayName => 'Postcode',
        StoredColnum => length($pc_prefix)}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => '${City}', StoredRownum => -2},
      {StoredTemplate => "$pc_prefix\$\{Postcode\}", StoredRownum => -1}
    ]
  };
}

# City on first line of address, postcode by itself on last line: Hungary
foreach my $code (qw(HU)) {
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  $per_country_data{$code} = {
    _format => [
      ['City', 40], ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40],
      ['Postcode', 4, qr/^\d{4}$/]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'City'},
      {StoredRownum => 1, DisplayName => 'Addr1'},
      {StoredRownum => 2, DisplayName => 'Addr2'},
      {StoredRownum => 3, DisplayName => 'Addr3'},
      {StoredRownum => 4, DisplayName => 'Addr4'},
      {StoredRownum => -1, DisplayName => 'Postcode', StoredColnum => 0}
    ],
    _d2s_map => [
      {StoredTemplate => '${City}', StoredRownum => 0},
      {StoredTemplate => '${Addr1}', StoredRownum => 1},
      {StoredTemplate => '${Addr2}', StoredRownum => 2},
      {StoredTemplate => '${Addr3}', StoredRownum => 3},
      {StoredTemplate => '${Addr4}', StoredRownum => 4},
      {StoredTemplate => '${Postcode}', StoredRownum => -1}
    ]
  };
}

# No city (or rather, only one): Singapore
foreach my $code (qw(SG)) {
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40],
      ['Postcode', 6, qr/^\d{6}$/]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -1, DisplayName => 'Postcode', StoredColnum => 10}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => 'SINGAPORE ${Postcode}', StoredRownum => -1}
    ]
  };
}

# District name, postcode (no city?): Bangladesh, Brunei Darussalam, Thailand
# XXX Bangladesh needs preprocessing of district names?
# XXX Brunei Darussalam is missing districts in Locale::SubCountry?
# XXX Thailand may use 9-digit postcodes in some cases.
foreach my $spec
    ((['BD', 4, qr/^\d{4}$/, qr/^(.+)\s*-\s*(\d{4})$/, ' - '],
      ['BN', 4, qr/^[bBkKtTpP]\w\d{4}$/,
       qr/^(.+)\s+([bBkKtTpP]\w\d{4})$/, ' - '],
      ['TH', 5, qr/^\d{5}$/, qr/^(.+)\s+(\d{5})$/, ' '])) {
  my ($code, $pc_len, $pc_re, $dp_re, $sep) = @$spec;
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  my $subctry = Locale::SubCountry->new($code);
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40], 2,
      ['District', { map { $_ => $_ } $subctry->all_full_names() } ],
      ['Postcode', $pc_len, $pc_re]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -1, DisplayName => 'District',
        StoredRegexnum => 0, StoredFieldnum => 0},
      {StoredRownum => -1, DisplayName => 'Postcode',
        StoredRegexnum => 0, StoredFieldnum => 1}
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => "\$\{District\}$sep\$\{Postcode\}",
        StoredRownum => -1}
    ],
    _regexes => [ $dp_re ]
  };
}

# City, no postcode or district: Barbados, Belize, Benin, Bolivia, Botswana,
# Burkina Faso, Burundi, Cameroon, Cayman Islands, Central African Republic,
# Chad, Comoros, Congo (Brazzaville), Congo (Kinshasa), Cote d'Ivoire,
# Democratic People's Republic of Korea (aka North Korea), Djibouti, Dominica,
# Equatorial Guinea, Eritrea, Fiji, Gambia, Ghana, Guyana, Hong Kong, Jamaica,
# Libya, Macao, Malawi, Mali, Mauritania, Mauritius, Namibia, Nigeria, Peru,
# Qatar, Rwanda, Saint Kitts and Nevis, Saint Lucia, Saint Vincent and the
# Grenadines, São Tomé and Principe, Sierra Leone, Suriname, Syrian Arab
# Republic, United Republic of Tanzania, Timor Leste, Togo, Tonga, Trinidad and
# Tobago, Tuvalu, Uganda, (Western) Samoa, Yemen, Zimbabwe
# XXX Not sure about Belize - it could be it has a district name, but if so,
# the districts Locale::SubCountry knows about aren't the right ones.
# XXX Bolivia could use district instead of city.
# XXX Not sure about Botswana - it could be it has a district name, but if so,
# the districts Locale::SubCountry knows about aren't the right ones.
# XXX Burkina Faso has 2 digits right of the city that may be (part of) a
# postcode. Also, all addresses are PO boxes and need the postcode-ish number
# prefixed?
# XXX Burundi could use district instead of city.
# XXX Central African Republic could use district instead of city.
# XXX Congo (Kinshasa) has a number after the city (at least in some cases),
# but I don't know whether that's a postcode. Until I do, leave it here.
# XXX Cote d'Ivoire actually has a 2-3 digit postcode duplicated on both ends
# of the "City" line, with a PO box just left of the city. Pretend it's all one
# big "City" field. May be better to leave it completely unstructured instead.
# XXX Djibouti could use district instead of city.
# XXX Gambia could use district instead of city.
# XXX Hong Kong postal info may be out of date, and I'm not sure about how
# Kowloon or New Territories fit in.
# XXX Jamaica needs a 1-2 digit suffix for Kingston.
# XXX Malawi needs a 1-digit suffix for Lilongwe.
# XXX Mauritania could use district instead of city.
# XXX Mauritius has an optional experimental postcode for 1 city only. Treat it
# as an unstructured address line for now.
# XXX Peru wants route numbers for some cities, and may introduce a postcode
# system eventually.
# XXX Qatar city may be optional in some cases.
# XXX Rwanda could use district instead of city.
# XXX Saint Kitts and Nevis could use district, island instead of city, but if
# so, Locale::SubCountry is missing both district and island names.
# XXX Saint Vincent and the Grenadines may want an extra address ligne below
# country. Ignore.
# XXX São Tomé and Principe may need district and or island specified for some
# addresses.
# XXX Suriname could use district instead of city.
# XXX Syrian Arab Republic could use district instead of city, and is currently
# developping a postcode system.
# XXX United Republic of Tanzania could use district instead of city.
# XXX Yemen could use district instead of city.
# XXX Zimbabwe could use district instead of city.
foreach my $code (qw(BB BZ BJ BO BW BF BI CM KY CF TD KM CG CI KP DJ DM GQ ER
                     FJ GM GH GY HK JM LY MO MW ML MR NA PE QA RW KN LC VC ST
                     SL SR SY TZ TL TG TT TV UG WS YE ZW)) {
  if (exists($per_country_data{$code})) {
    die __PACKAGE__ . ": Attempted to initialize country code $code twice.\n";
  }
  $per_country_data{$code} = {
    _format => [
      ['Addr1', 40], ['Addr2', 40], ['Addr3', 40], ['Addr4', 40], ['City', 40]
    ],
    _s2d_map => [
      {StoredRownum => 0, DisplayName => 'Addr1'},
      {StoredRownum => 1, DisplayName => 'Addr2'},
      {StoredRownum => 2, DisplayName => 'Addr3'},
      {StoredRownum => 3, DisplayName => 'Addr4'},
      {StoredRownum => -1, DisplayName => 'City'},
    ],
    _d2s_map => [
      {StoredTemplate => '${Addr1}', StoredRownum => 0},
      {StoredTemplate => '${Addr2}', StoredRownum => 1},
      {StoredTemplate => '${Addr3}', StoredRownum => 2},
      {StoredTemplate => '${Addr4}', StoredRownum => 3},
      {StoredTemplate => '${City}', StoredRownum => -1}
    ]
  };
}

1;

=head1 BUGS

Only 2-letter country codes are supported.

A knob to carp on some errors would be nice.

Objects returned by the new method can be actually blessed into a
country-specific subclass. This makes it impossible to have other
derived classes than the country-specific ones.

40 is used as the suggested length for all text fields. This is probably too
long for some and too short for others.

Support for most countries ranges from non-existent to sketchy.

The method name "display" is arguably a poor choice.

Some messages should go through a translation table.

Data validation should probably be a method of its own.

This module doesn't yet deal well with countries that want the recipient name
in another position than 1st line, or the country name in another position than
last line. Examples of such countries are: Ukraine (wants country,
city+postcode, street address, recipient name from top down instead of the more
widespread bottom up), Turkmenistan (wants city+postcode, country, recipient
name, street address, from top down), Grenada (wants a supranational line -
West Indies - below the country name). The interface to do that exists, but is
do-nothing until I figure out how to deal with address formats for use between
countries with conflicting requirements.

This module doesn't deal well with countries where the address format depends
on the script used, such as Saudi Arabia.

This module doesn't yet support entities with their own ISO 3166-1 code that
use another country's address format, including the country name.

This module assumes "no locale", and blissfully mixes character classes that
could conceivably match in the locale with classes that have to match according
to the Roman alphabet (eg, US ZIP codes and Canadian postal codes). This is
probably nearly impossible to fix, as the relevant locale isn't well-defined
anyway. (The locale for the machine running the application? The locale for the
user? Or the locale for the country the address is in?)

This module assumes that the privileged order for entering address components
is top-down, left-to right, according to the standard or most common address
format. This may not be true of countries where the dominant language is
written right-to-left.

This module doesn't use the PATDL
(F<http://xml.coverpages.org/Lubenow-PATDL200204.pdf>) in the address parsing
rules.

=head1 HISTORY

=head1 SEE ALSO

L<Locale::Country(3)>

L<Locale::Subcountry(3)>

F<http://www.upu.int/post_code/en/postal_addressing_systems_member_countries.shtml>

F<http://www.bitboost.com/ref/international-address-formats.html>

F<http://www.indiapost.org/Netscape/Pincode.html>

F<http://www.sterlingdata.com/colombia.htm>

F<http://mailservices.berkeley.edu/intladdr.pdf> (previous version of the first
URL, incorrect in spots, and to be used only if no other info is available)

F<http://www.kevinandkell.com/>

=head1 CONTRIBUTORS

Ailbhe, DamienPS, LeiaCat, Renée, and Martin DeMello clarified, corrected, or
explained standards or usage for specific countries. See acknowledgements in
comments throughout the source code.

Bill Holbrook draws (and holds the copyright to) comic strip Kevin and Kell,
from which I got the names used in the description for C<$parser-E<gt>label()>.

=head1 AUTHOR AND LICENSE

Copyright (c) 2004, Michel Lavondès. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

=over 4

=item *

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

=item *

Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

=item *

Neither the name of the Copyright holder nor the names of any contributors may
be used to endorse or promote products derived from this software without
specific prior written permission.

=back

This software is provided by the copyright holder and contributors "as is" and
any express or implied warranties, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose are
disclaimed. In no event shall the copyright holder or contributors be liable
for any direct, indirect, incidental, special, exemplary, or consequential
damages (including, but not limited to, procurement of substiture goods or
services; loss of use, data, or profits; or business interruption) however
caused and on any theory of liability, whether in contract, strict liability,
or tort (including negligence or otherwise) arising in any way out of the use
of this software, even if advised of the possibility of such damage.
