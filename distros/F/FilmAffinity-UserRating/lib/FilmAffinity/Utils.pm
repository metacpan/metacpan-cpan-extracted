package FilmAffinity::Utils;

use strict;
use warnings;

use Readonly;
use LWP::RobotUA;

=head1 NAME

FilmAffinity::Utils - Utils for FilmAffinity

=head1 VERSION

Version 1.01

=cut

our $VERSION = 1.01;

=head1 SYNOPSIS

  use FilmAffinity::Utils;

  my $string = demoronize($string);
  my $ua = buildRobot($delay);
  my $tsv = data2tsv($data);

=head1 DESCRIPTION

Several utilities functions

=cut

use base 'Exporter';
our @EXPORT_OK = qw/demoronize buildRobot data2tsv/;

Readonly::Scalar my $SECONDS => 60;

=head1 SUBROUTINES/METHODS

=head2 demoronize

Remove funky Windows 'smart' characters.

Most of this code is borrowed from Catalyst::Plugin::Params::Demoronize

=cut

sub demoronize {
  my $str = shift;

  return $str unless defined $str;

  my $demoronizeReplaceMap = {
    q{\x{201A}|\x82}   => q{,},   # 82, SINGLE LOW-9 QUOTATION MARK
    q{\x{201E}|\x84}   => q{,,},  # 84, DOUBLE LOW-9 QUOTATION MARK
    q{\x{2026}|\x85}   => q{...}, # 85, HORIZONTAL ELLIPSIS
    q{\x{02C6}|\x88}   => q{^},   # 88, MODIFIER LETTER CIRCUMFLEX ACCENT
    q{\x{2018}|\x91}   => q{`},   # 91, LEFT SINGLE QUOTATION MARK
    q{\x{2019}|\x92}   => q{'},   # 92, RIGHT SINGLE QUOTATION MARK
    q{\x{201C}|\x93}   => q{"},   # 93, LEFT DOUBLE QUOTATION MARK
    q{\x{201D}|\x94}   => q{"},   # 94, RIGHT DOUBLE QUOTATION MARK
    q{\x{2022}|\x95|•} => q{*},   # 95, BULLET
    q{\x{2013}|\x96}   => q{-},   # 96, EN DASH
    q{\x{2014}|\x97}   => q{-},   # 97, EM DASH
    q{\x{2039}|\x8B}   => q{<},   # 8B, SINGLE LEFT-POINTING ANGLE QUOTATION MARK
    q{\x{203A}|\x9B}   => q{>},   # 9B, SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
  };

  foreach my $replace ( keys %{$demoronizeReplaceMap} ) {
    my $replacement = $demoronizeReplaceMap->{$replace};
    $str =~ s/$replace/$replacement/xmsg;
  }

  return $str;
}

=head2 buildRobot

Returns a LWP::RobotUA for web requests

=cut

sub buildRobot {
  my ($delay) = shift;

  my $ua = LWP::RobotUA->new( "FilmAffinity-Bot/$VERSION", 'me@foo.com' );
  $ua->timeout($SECONDS);
  $ua->env_proxy;
  $ua->delay( $delay / $SECONDS );

  return $ua;
}

=head2 data2tsv

Transform FilmAffinity::UserRating in tab separated value

Returns a tsv string

=cut

sub data2tsv {
  my ($data) = shift;

  my $tsvString;
  foreach my $mov ( sort { p_sortByRatings($data) } keys %{$data} ) {
    $tsvString .= $mov . "\t" . $data->{$mov}{'title'} . "\t"
      . $data->{$mov}{'rating'} . "\n";
  }

  return $tsvString;
}

sub p_sortByRatings {
  my ($ref_movies) = @_;
  return $ref_movies->{$b}{'rating'} <=> $ref_movies->{$a}{'rating'};
}

=head1 AUTHOR

William Belle, C<< <william.belle at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-filmaffinity-userrating at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FilmAffinity-UserRating>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FilmAffinity::Utils

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FilmAffinity-UserRating>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FilmAffinity-UserRating>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FilmAffinity-UserRating>

=item * Search CPAN

L<http://search.cpan.org/dist/FilmAffinity-UserRating/>

=back

=head1 SEE ALSO

L<http://www.filmaffinity.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 William Belle.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of FilmAffinity::Utils
