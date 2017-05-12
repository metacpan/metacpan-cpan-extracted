#!/usr/bin/env perl
package Dist::Zilla::Plugin::ChangesFromYaml::Convert;

our $VERSION = '0.005'; # VERSION

use 5.010;
use strict;
use warnings;
use Carp;
use YAML::XS;
use CPAN::Changes;
use DateTime::Format::CLDR;
use Exporter 'import';
our @EXPORT_OK = qw(convert);

sub convert {
    my ( $changes_yml, $dateformat ) = @_;
    my $changes = CPAN::Changes->new;

    my @releases = Load($changes_yml);

    for (@releases) {
        if ($dateformat) {
            $_->{date} = _convert_date( $_->{date}, $dateformat );
        }
        my $rel = CPAN::Changes::Release->new(
            version => $_->{version},
            date    => $_->{date},
        );

        $rel->add_changes($_) for @{ $_->{changes} };
        $changes->add_release($rel);
    }
    return $changes->serialize;
}

sub _convert_date {
    my ( $date, $format ) = @_;

    # `date` outputs:
    # pattern => 'ccc MMM dd HH:mm:ss zzz yyyy'
    # Ugly hack. ccc doesn't seem to recognize UTC
    # I don't know if this replacement is technically correct but solves my problem now.
    if ($format =~ /ccc/ and $date =~ /UTC/) {
        $date =~ s/UTC/GMT/;
    }

    my $dt =
      DateTime::Format::CLDR->new( pattern => $format )->parse_datetime($date);

    croak "Failed to parse date ($date) using dateformat ($format)"
      unless $dt;

    return DateTime::Format::CLDR->new( pattern => 'yyyy-MM-dd HH:mm:ss zzz' )
      ->format_datetime($dt);
}

1;
