package Geo::Location::IP::Model::Insights;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Model::Insights
    :isa(Geo::Location::IP::Model::City);

our $VERSION = 0.001;

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Model::Insights - Records associated with a city

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $insights_model = $web_service_client->insights(ip => '1.2.3.4');
  my $city           = $insights_model->city;
  my $country        = $insights_model->country;
  printf "%s in %s\n", $city->name, $country->name;

=head1 DESCRIPTION

This class contains records from a web service query.

The class differs from the L<Geo::Location::IP::Model::City> class only in the
number of populated fields.

=head1 SUBROUTINES/METHODS

See L<Geo::Location::IP::Model::City>.

=for Pod::Coverage DOES META

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
