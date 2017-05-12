use 5.006;    # our
use strict;
use warnings;

package Gentoo::VDB;

our $VERSION = '0.001002';

# ABSTRACT: Simple API for querying VDB Implementations

# AUTHORITY

# Note: VDB format is not well defined, and its an implementation
# detail of Portage itself, which fortunately is mostly similar to
# the implementations in other Portage clients.
#
# However, there's no requirement that the VDB definition be any
# specific way, as the only PMS requirement is that every PMS
# implementation *should* have a VDB of some description, but
# the definition is up to the implementer.
#
# Hence, all this design is to make that doable.
our $BACKENDS = {
    'portage' => sub {
        require Gentoo::VDB::Portage;
        return 'Gentoo::VDB::Portage';
    },
};

sub new {
    my ( $self, @args ) = @_;
    my $config = { ref $args[0] ? %{ $args[0] } : @args };
    my $backend_name = delete $config->{backend} || 'portage';
    die "Unknown backend $backend_name"
      unless exists $BACKENDS->{$backend_name};
    my $backend_module = $BACKENDS->{$backend_name}->();
    my $backend        = $backend_module->new($config);
    return bless { backend => $backend, config => $config }, $self;
}

# ->categories() -> list of CAT
sub categories { $_[0]->{backend}->categories( @_[ 1 .. $#_ ] ) }

# ->packages()            -> list of CAT/PN-V
# ->packages({ in => 'dev-perl' })  -> list of CAT/PN-V in dev-perl/
sub packages { $_[0]->{backend}->packages( @_[ 1 .. $#_ ] ) }

# ->properties({ for => 'cat/pn-v' })  -> list of HASH
sub properties { $_[0]->{backend}->properties( @_[ 1 .. $#_ ] ) }

# ->get_property({ for => 'cat/pn-v', property => 'propname' }) -> HASH
sub get_property { $_[0]->{backend}->get_property( @_[ 1 .. $#_ ] ) }

1;

=head1 NAME

Gentoo::VDB - Simple API for querying Gentoo's installed-package database

=head1 SYNOPSIS

  use Gentoo::VDB;
  my $vdb = Gentoo::VDB->new();

  my (@categories) = $vdb->categories;
  ## Note: next line is slow
  my (@packages)   = $vdb->packages;
  ## Much faster
  my (@packages)   = $vdb->packages({ in => 'dev-perl' });

=head1 METHODS

=head2 C<new>

  my $instance = Gentoo::VDB->new(\%ARGS);

=head2 C<categories>

Returns a list of single-token category names that are
valid.

  my (@categories) = $vdb->categories;

Note: Categories that have no definite installed
packages are omitted, even if their dirs are present.

This is mostly because this is the only way to disambiguate between
a temporary directory and a category.

It is mostly equivalent to

  find /var/db/pkg \
    -maxdepth 1 \
    -mindepth 1 \
    -not -empty \
    -printf '%f\n'

And should be similarly performant.

=head2 C<packages>

Returns a list of valid packages in C<CAT/PN-VERSION> form.

  my ( @packages ) = $vdb->packages();
  # Show only packages in dev-perl, much faster
  my ( @packages ) = $vdb->packages({ in => 'dev-perl' });

This is mostly equivalent to:

  find /var/db/pkg      \
      -maxdepth 2       \
      -mindepth 2       \
      -not -empty       \
      -printf '%p\n' |  \
    sed -r 's|^.*/([^/]+)/([^/]+)$|\1/\2|'
or

  find /var/db/pkg/dev-perl   \
      -maxdepth 1             \
      -mindepth 1             \
      -not -empty             \
      -printf '%p\n'        | \
    sed -r 's|^.*/([^/]+)/([^/]+)$|\1/\2|'

And should be similarly performant.

=head2 C<properties>

Returns a list of hash entries describing properties of the given C<CAT/PN-VERSION>

  my ( @properties ) = $vdb->properties({ for => 'dev-lang/perl-5.22.1-r1' });

A property contains:

  {
    property =>  .... # the name of the property ( backend specific )
    label    =>  .... # usually the same as 'property' but is defined by
                      # Gentoo::VDB, some special cases like
                      # 'special:source_ebuild' and 'unknown:' . $property
                      # exist.
    type     =>  .... # Gentoo::VDB specific hint for decoding the
                      # data.
    for      =>  .... # CAT/PN-V entry

    # Selectively ...
    content  =>       # For "generic" types like "file", this is generally
                      # a MIME type for the undelying decoded data.
                      # ie: No VDB Specific decoding hint, just amorphous
                      # blob of bytes that have to be handled thusly
                      # eg: text/plain, application/octet-stream

    encoding =>       # if the data has some sort of protocol encoding,
                      # for instance, a bzip encoded text source
                      # this will be populated respectively, eg:
                      # application/x-bzip2
  }

A given record may overlap with another record in part, eg: One "property"
may yield 2 different hashes with different labels and types.

But this is just an idea at this stage, and there's no implementation behind it.

Mostly pertinent for large objects like `environment.bz2` that can yield additional
metadata.

=head2 C<get_property>

Fetch a given property as a string blob

  my $prop = $vdb->get_property({ for => 'dev-lang/perl-5.22.1-r1', property => 'BackendName' });

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 LICENSE

This software is copyright (c) 2016 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
