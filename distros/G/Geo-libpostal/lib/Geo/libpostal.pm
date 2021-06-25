package Geo::libpostal;
use strict;
use warnings;
use XSLoader;
use Exporter 5.57 'import';
use Const::Fast;

const our $ADDRESS_NONE         => 0;
const our $ADDRESS_ANY          => 1 << 0;
const our $ADDRESS_NAME         => 1 << 1;
const our $ADDRESS_HOUSE_NUMBER => 1 << 2;
const our $ADDRESS_STREET       => 1 << 3;
const our $ADDRESS_UNIT         => 1 << 4;


const our $ADDRESS_LOCALITY     => 1 << 7;
const our $ADDRESS_ADMIN1       => 1 << 8;
const our $ADDRESS_ADMIN2       => 1 << 9;
const our $ADDRESS_ADMIN3       => 1 << 10;
const our $ADDRESS_ADMIN4       => 1 << 11;
const our $ADDRESS_ADMIN_OTHER  => 1 << 12;
const our $ADDRESS_COUNTRY      => 1 << 13;
const our $ADDRESS_POSTAL_CODE  => 1 << 14;
const our $ADDRESS_NEIGHBORHOOD => 1 << 15;
const our $ADDRESS_ALL          => (1 << 16) - 1;

our $VERSION     = '0.08';
our %EXPORT_TAGS = ( 'all' => [qw/
    expand_address
    parse_address
    $ADDRESS_NONE
    $ADDRESS_ANY
    $ADDRESS_NAME
    $ADDRESS_HOUSE_NUMBER
    $ADDRESS_STREET
    $ADDRESS_UNIT
    $ADDRESS_LOCALITY
    $ADDRESS_ADMIN1
    $ADDRESS_ADMIN2
    $ADDRESS_ADMIN3
    $ADDRESS_ADMIN4
    $ADDRESS_ADMIN_OTHER
    $ADDRESS_COUNTRY
    $ADDRESS_POSTAL_CODE
    $ADDRESS_NEIGHBORHOOD
    $ADDRESS_ALL
  /]);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

XSLoader::load('Geo::libpostal', $VERSION);

1;
__END__
=encoding utf8

=head1 NAME

Geo::libpostal - Perl bindings for libpostal

=head1 SYNOPSIS

  use Geo::libpostal ':all';

  # normalize an address
  my @addresses = expand_address('120 E 96th St New York');

  # parse addresses into their components
  my %address = parse_address('The Book Club 100-106 Leonard St Shoreditch London EC2A 4RH, United Kingdom');

  # %address contains:
  # (
  #   road         => 'leonard st',
  #   postcode     => 'ec2a 4rh',
  #   house        => 'the book club',
  #   house_number => '100-106',
  #   suburb       => 'shoreditch',
  #   country      => 'united kingdom',
  #   city         => 'london'
  # );

=head1 DESCRIPTION

libpostal is a C library for parsing/normalizing international street addresses. Address strings can be normalized using C<expand_address> which returns a list of valid variations so you can check for duplicates in your dataset. It supports normalization in over L<60 languages|https://github.com/openvenues/libpostal/tree/master/resources/dictionaries>. An address string can also be parsed into its constituent parts using C<parse_address> such as house name, number, city and postcode.

=head1 FUNCTIONS

=head2 expand_address

  use Geo::libpostal 'expand_address';

  my @ny_addresses = expand_address('120 E 96th St New York');
  my @fr_addresses = expand_address('Quatre vingt douze R. de l\'Église');

Takes an address string and returns a list of known variants. Useful for normalization. Accepts many boolean options:

  expand_address('120 E 96th St New York',
      latin_ascii => 1,
      transliterate => 1,
      strip_accents => 1,
      decompose => 1,
      lowercase => 1,
      trim_string => 1,
      drop_parentheticals => 1,
      replace_numeric_hyphens => 1,
      delete_numeric_hyphens => 1,
      split_alpha_from_numeric => 1,
      replace_word_hyphens => 1,
      delete_word_hyphens => 1,
      delete_final_periods => 1,
      delete_acronym_periods => 1,
      drop_english_possessives => 1,
      delete_apostrophes => 1,
      expand_numex => 1,
      roman_numerals => 1,
  );

B<Warning>: old versions of libpostal L<segfault|https://github.com/openvenues/libpostal/issues/79> if all options are set to false. C<Geo::libpostal> includes a unit test for this.

Also accepts an arrayref of language codes per L<ISO 639-1|https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes>:

 expand_address('120 E 96th St New York', languages => [qw(en fr)]);

This is useful if you are normalizing addresses in multiple languages.

Finally C<expand_address> accepts an option for which address C<components> to expand. This is a 16 bit integer bitmask. These constants are exported with the C<:all> tag:

  $ADDRESS_NONE
  $ADDRESS_ANY
  $ADDRESS_NAME
  $ADDRESS_HOUSE_NUMBER
  $ADDRESS_STREET
  $ADDRESS_UNIT
  $ADDRESS_LOCALITY
  $ADDRESS_ADMIN1
  $ADDRESS_ADMIN2
  $ADDRESS_ADMIN3
  $ADDRESS_ADMIN4
  $ADDRESS_ADMIN_OTHER
  $ADDRESS_COUNTRY
  $ADDRESS_POSTAL_CODE
  $ADDRESS_NEIGHBORHOOD
  $ADDRESS_ALL

These are the default components used by libpostal:

  use Geo::libpostal ':all';

  expand_address('120 E 96th St New York',
    components => $ADDRESS_NAME | $ADDRESS_HOUSE_NUMBER | $ADDRESS_STREET | $ADDRESS_UNIT
  );

The constant C<$ADDRESS_ALL> uses all components:

  expand_address('120 E 96th St New York',
    components => $ADDRESS_ALL
  );

C<expand_address> will C<die> on C<undef> and empty addresses, odd numbers of options and unrecognized options. Exported on request.

=head2 parse_address

  use Geo::libpostal 'parse_address';

  my %ny_address = parse_address('120 E 96th St New York');
  my %fr_address = parse_address('Quatre vingt douze R. de l\'Église');

=cut

=pod

Will C<die> on C<undef> and empty addresses. Exported on request.

C<parse_address> may return L<duplicate labels|https://github.com/openvenues/libpostal/issues/27> for invalid addresses
strings.

=head1 WARNING

libpostal uses C<setup> and C<teardown> functions. Setup is lazily loaded. Teardown occurs in an C<END> block automatically.

=over 4

=item *

Old versions of libpostal C<Geo::libpostal> will L<segfault|https://github.com/openvenues/libpostal/issues/82> if C<_teardown()> is called twice (this module includes a unit test for this).

=item *

If C<expand_address> or C<parse_address> is called after teardown, old versions of libpostal will L<error|https://github.com/openvenues/libpostal/pull/86> (this module includes a unit test for this too).

=item *

libpostal is not L<thread-safe|https://github.com/openvenues/libpostal/issues/34>.

=back

=head1 EXTERNAL DEPENDENCIES

L<libpostal|https://github.com/openvenues/libpostal> is required. This has been tested against L<v1.0.0|https://github.com/openvenues/libpostal/releases/tag/v1.0.0>.

=head1 INSTALLATION

You can install this module with CPAN:

  $ cpan Geo::libpostal

Or clone it from GitHub and install it manually:

  $ git clone https://github.com/dnmfarrell/Geo-libpostal
  $ cd Geo-libpostal
  $ perl Makefile.PL
  $ make
  $ make test
  $ make install

=head1 AUTHOR

E<copy> 2021 David Farrell

=head1 LICENSE

See LICENSE

=cut
