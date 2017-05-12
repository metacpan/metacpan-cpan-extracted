use 5.006;
use strict;
use warnings;

package Metabase::Resource::cpan;

our $VERSION = '0.025';

use Carp ();

use Metabase::Resource;
our @ISA = qw/Metabase::Resource/;

sub _extract_type {
    my ( $self, $resource ) = @_;
    my ($type) = $resource =~ m{\Acpan:///([^/]+)/};
    Carp::confess("could not determine Metabase::Resource type from '$resource'\n")
      unless defined $type && length $type;
    return __PACKAGE__ . "::$type";
}

1;

# ABSTRACT: class for Metabase resources

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Resource::cpan - class for Metabase resources

=head1 VERSION

version 0.025

=head1 SYNOPSIS

  my $resource = Metabase::Resource->new(
    'cpan:///distfile/RJBS/Metabase-Fact-0.001.tar.gz',
  );

  my $resource_meta = $resource->metadata;
  my $typemap       = $resource->metadata_types;

=head1 DESCRIPTION

Generates resource metadata for resources of the scheme 'cpan'.

The L<Metabase::Resource::cpan> class supports the following sub-type(s).

=head2 distfile

  my $resource = Metabase::Resource->new(
    'cpan:///distfile/RJBS/URI-cpan-1.000.tar.gz',
  );

For the example above, the resource metadata structure would contain the
following elements:

  scheme       => cpan
  type         => distfile
  dist_file    => RJBS/URI-cpan-1.000.tar.gz
  cpan_id      => RJBS
  dist_name    => URI-cpan
  dist_version => 1.000

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
