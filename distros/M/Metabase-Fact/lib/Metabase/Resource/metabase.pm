use 5.006;
use strict;
use warnings;

package Metabase::Resource::metabase;

our $VERSION = '0.025';

use Carp ();

use Metabase::Resource;
our @ISA = qw/Metabase::Resource/;

my $hex     = '[0-9a-f]';
my $guid_re = qr(\A$hex{8}-$hex{4}-$hex{4}-$hex{4}-$hex{12}\z)i;

sub _validate_guid {
    my ( $self, $string ) = @_;
    if ( $string !~ $guid_re ) {
        Carp::confess("'$string' is not formatted as a GUID string");
    }
    return $string;
}

sub _extract_type {
    my ( $self, $resource ) = @_;

    # determine type
    my ($type) = $resource =~ m{\Ametabase:([^:]+)};
    Carp::confess("could not determine URI type from '$resource'\n")
      unless defined $type && length $type;
    return __PACKAGE__ . "::$type";
}

1;

# ABSTRACT: class for Metabase resources

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Resource::metabase - class for Metabase resources

=head1 VERSION

version 0.025

=head1 SYNOPSIS

  my $resource = Metabase::Resource->new(
    "metabase:user:B66C7662-1D34-11DE-A668-0DF08D1878C0"
  );

  my $resource_meta = $resource->metadata;
  my $typemap       = $resource->metadata_types;

=head1 DESCRIPTION

Generates resource metadata for resources of the scheme 'metabase'.

The L<Metabase::Resource::metabase> class supports the following sub-type(s).

=head2 fact 

  my $resource = Metabase::Resource->new(
    "metabase:fact:bd83d51e-0eea-11df-8413-0018f34ec37c"
  );

This resource is for a generic Metabase Fact.  (I.e. for a Fact about another
Fact).  For the example above, the resource metadata structure would contain
the following elements:

  scheme       => metabase
  type         => user
  fact         => bd83d51e-0eea-11df-8413-0018f34ec37c

=head2 user

  my $resource = Metabase::Resource->new(
    "metabase:user:b66c7662-1d34-11de-a668-0df08d1878c0"
  );

This resource is for a Metabase user. (I.e. corresponding to the GUID of a
Metabase::User::Profile.) For the example above, the resource metadata
structure would contain the following elements:

  scheme       => metabase
  subtype      => user
  user         => b66c7662-1d34-11de-a668-0df08d1878c0

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.
Bugs can be submitted through the web interface at
L<http://rt.cpan.org/Dist/Display.html?Queue=Metabase-Fact>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

H.Merijn Brand <hmbrand@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
