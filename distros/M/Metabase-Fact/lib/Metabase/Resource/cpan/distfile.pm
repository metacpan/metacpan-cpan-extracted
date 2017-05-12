use 5.006;
use strict;
use warnings;

package Metabase::Resource::cpan::distfile;

our $VERSION = '0.025';

use Carp               ();
use CPAN::DistnameInfo ();

use Metabase::Resource::cpan;
our @ISA = qw/Metabase::Resource::cpan/;

sub _metadata_types {
    return {
        cpan_id      => '//str',
        dist_file    => '//str',
        dist_name    => '//str',
        dist_version => '//str',
    };
}

sub _init {
    my ($self) = @_;

    # determine subtype
    my ($string) = $self =~ m{\Acpan:///distfile/(.+)\z};
    Carp::confess("could not determine distfile from '$self'\n")
      unless defined $string && length $string;

    my $data = $self->_validate_distfile($string);
    for my $k ( keys %$data ) {
        $self->_add( $k => $data->{$k} );
    }
    return $self;
}

# distfile validates during _init, really
sub validate { 1 }

# XXX should really validate AUTHOR/DISTNAME-DISTVERSION.SUFFIX
# -- dagolden, 2010-01-27
#
# my $suffix = qr{\.(?:tar\.(?:bz2|gz|Z)|t(?:gz|bz)|zip)};
#
# for now, we'll use CPAN::DistnameInfo;
#

# map DistnameInfo calls to our names
my %distfile_map = (
    cpanid  => 'cpan_id',
    dist    => 'dist_name',
    version => 'dist_version',
);

sub _validate_distfile {
    my ( $self, $string ) = @_;
    my $two = substr( $string, 0, 2 );
    my $one = substr( $two,    0, 1 );
    my $path = "authors/id/$one/$two/$string";
    my $d    = eval { CPAN::DistnameInfo->new($path) };
    my $bad  = defined $d ? 0 : 1;

    my $cache = { dist_file => $string };

    for my $k ( $bad ? () : ( keys %distfile_map ) ) {
        my $value = $d->$k;
        defined $value or $bad++ and last;
        $cache->{ $distfile_map{$k} } = $value;
    }

    if ($bad) {
        Carp::confess("'$string' can't be parsed as a CPAN distfile");
    }
    return $cache;
}

1;

# ABSTRACT: class for Metabase resources

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Resource::cpan::distfile - class for Metabase resources

=head1 VERSION

version 0.025

=head1 SYNOPSIS

  my $resource = Metabase::Resource->new(
    'cpan:///distfile/RJBS/Metabase-Fact-0.001.tar.gz',
  );

  my $resource_meta = $resource->metadata;
  my $typemap       = $resource->metadata_types;

=head1 DESCRIPTION

Generates resource metadata for resources of the scheme 'cpan:///distfile'.

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
