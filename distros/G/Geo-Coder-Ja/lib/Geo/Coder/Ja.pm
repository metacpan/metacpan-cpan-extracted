package Geo::Coder::Ja;
use strict;
use warnings;
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK);

use Carp;

BEGIN {
    $VERSION = '0.03';
    if ($] > 5.006) {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $VERSION);
    } else {
        require DynaLoader;
        @ISA = qw(DynaLoader);
        __PACKAGE__->bootstrap;
    }

    require Exporter;
    push @ISA, 'Exporter';

    %EXPORT_TAGS = (all => [qw(
        DB_AUTO
        DB_GYOSEI
        DB_CHO
        DB_AZA
        DB_GAIKU
        DB_JUKYO
    )]);
    @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;
}

sub new {
    my ($class, %opt) = @_;
    croak 'paramater dbpath is required' unless exists $opt{dbpath};
    $opt{load_level} ||= DB_AUTO;
    $opt{encoding}   ||= 'SHIFT_JIS';
    my $self = bless {}, $class;
    $self->load($opt{dbpath}, $opt{load_level});
    $self->encoding($opt{encoding});
    $self;
}

sub encoding {
    my $self = shift;
    if (@_ > 0) {
        $self->{encoding} = $_[0];
        $self->set_encoding($_[0]);
    } else {
        $self->{encoding};
    }
}

sub geocode {
    my $self = shift;
    my %param;
    if (@_ % 2 == 0) {
        %param = @_;
    } else {
        $param{location} = shift;
    }
    if (!exists $param{location} and !exists $param{postcode}) {
        croak('Usage: geocode(location => $location) or geocode(postcode => $postcode)');
    }
    if (exists $param{location}) {
        $self->geocode_location($param{location});
    } else {
        $self->geocode_postcode($param{postcode});
    }
}

1;
__END__

=head1 NAME

Geo::Coder::Ja - geocoder.ja library module for Perl

=head1 SYNOPSIS

  use Geo::Coder::Ja;

  my $geocoder = Geo::Coder::Ja->new(
      dbpath     => '/usr/local/share/geocoderja', # required
      load_level => DB_AUTO,  # optional. default DB_AUTO
      encoding   => 'UTF-8',  # optional. default 'SHIFT_JIS'
  );
  # same as $geocoder->geocode($location);
  my $location = $geocoder->geocode(location => $location);
  # $location->{latitude}
  # $location->{longitude}
  # $location->{address}
  # $location->{address_kana}

=head1 DESCRIPTION

This module is an interface for geocoder.ja library.
It is available at: http://www.postlbs.org/postlbs-cms/ja/geocoder

=head1 METHODS

=head2 new(%options)

It should be called with following arguments (items with default value are optional)

  dbpath     => geocoder.ja's database files directory
  load_level => load level. must be DB_AUTO, DB_JUKYO, DB_GAIKU, DB_AZA, DB_CHO or DB_GYOSEI.
  encoding   => default 'SHIFT_JIS'. must be 'UTF-8', 'EUC-JP' or 'SHIFT_JIS'.

Returns an instance of this module.

=head2 geocode(%param)

geocode(location => $location) or geocode(postcode => $postcode) are supported.

Get latitude/longitude from the address or postcode.

Returns a hashref, contains the following fields:

  latitude
  longitude
  address
  address_kana

Returns undef if multiple candidates or failure.

=head2 encoding([$encoding])

Set/get encoding. $encoding must be 'UTF-8', 'EUC-JP' or 'SHIFT_JIS'.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://www.postlbs.org/postlbs-cms/ja/geocoder>

=cut
