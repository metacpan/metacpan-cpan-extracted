package Geo::Address::Mail::Standardizer;
use Moose::Role;

our $VERSION = '0.02';

requires 'standardize';

1;

=head1 NAME

Geo::Address::Mail::Standardizer - A role for Geo::Address::Mail standardization

=head1 SYNOPSIS

This module provides an interface for writing address standardization as
well as a class to represent the results of a standarization process.

    package Geo::Address::Mail::Standardizer::My;
    use Moose;

    with 'Geo::Address::Mail::Standardizer';

    # use it

    my $std = Geo::Address::Mail::Standardizer::My->new(...);
    my $address = Geo::Address::Mail::MyCountry;
    my $results = $std->standardize($address);

=head1 WRITING A STANDARDIZER

This module provides a simple API.  Your Standardizer implementation is likely
for a specific locale such as the US, UK or whatever.  You should
provide a C<standardize> method that accepts the appropriate subclass 
(Geo::Address::Mail::YourCountry).  You would then use the information in the
supplied address object with your standardization mechanism.  You should
B<not> change the argument.  Instead, create a new Address object and use it
with the L<Geo::Address::Mail::Standardizer::Results> object, setting any
changed values:

  sub standardize {
      my ($self, $address) = @_;

      # contact the USPS or your local postal service in your country
      # or implement some algorithm or whatever

      my $results = Geo::Address::Mail::Standardizer::Results->new;
      my $new_addr = $address->clone;
      for(...) { # iterate over the results of your standardization mechanism
        $results->set_changed($field, $new_value) if $changed;
        $new_addr->$field($new_value);
      }

      return $results;
  }

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
