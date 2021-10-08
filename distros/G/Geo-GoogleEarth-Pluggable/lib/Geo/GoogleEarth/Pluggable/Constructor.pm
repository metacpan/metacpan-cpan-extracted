package Geo::GoogleEarth::Pluggable::Constructor;
use warnings;
use strict;
use base qw{Package::New};

our $VERSION='0.17';

=head1 NAME

Geo::GoogleEarth::Pluggable::Constructor - Geo::GoogleEarth::Pluggable Constructor package

=head1 SYNOPSIS

  use base qw{Geo::GoogleEarth::Pluggable::Constructor};

=head1 DESCRIPTION

The is the constructor for all Geo::GoogleEarth::Pluggable packages.

=head1 USAGE

=head1 CONSTRUCTOR

=head2 new

  my $document = Geo::GoogleEarth::Pluggable->new(key1=>value1,
                                                  key2=>[value=>{opt1=>val1}],
                                                  key3=>{value=>{opt2=>val2}});

=head1 METHODS

=head2 document

Always returns the document object.  Every object should know what document it is in.

=cut

sub document {shift->{"document"}};

=head1 BUGS

Please log on RT and send to the geo-perl email list.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis (mrdvt92)
  CPAN ID: MRDVT

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Geo::GoogleEarth::Pluggable> creates a GoogleEarth Document.

=cut

1;
