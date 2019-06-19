package MaxMind::DB::Reader::XS;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.000008';

use 5.010000;

# We depend on these in the C/XS code.
use Math::Int64  ();
use Math::Int128 ();

use MaxMind::DB::Metadata 0.040001;
use MaxMind::DB::Types qw( Int Str );

use Moo;

with 'MaxMind::DB::Reader::Role::HasMetadata';

use XSLoader;

## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
XSLoader::load( __PACKAGE__, $VERSION );
## use critic

has file => (
    is       => 'ro',
    isa      => Str,
    coerce   => sub { "$_[0]" },
    required => 1,
);

has _mmdb => (
    is        => 'ro',
    init_arg  => undef,
    lazy      => 1,
    builder   => '_build_mmdb',
    predicate => '_has_mmdb',
);

# XXX - making this private & hard coding this is obviously wrong - eventually
# we need to expose the flag constants in Perl
has _flags => (
    is       => 'ro',
    isa      => Int,
    init_arg => undef,
    default  => 0,
);

sub BUILD { $_[0]->_mmdb }

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub record_for_address {
    return $_[0]->__data_for_address( $_[0]->_mmdb, $_[1] );
}

sub iterate_search_tree {
    my $self          = shift;
    my $data_callback = shift;
    my $node_callback = shift;

    return $self->_iterate_search_tree(
        $self->_mmdb, $data_callback,
        $node_callback
    );
}

sub _build_mmdb {
    my $self = shift;

    return $self->_open_mmdb( $self->file, $self->_flags );
}

sub _build_metadata {
    my $self = shift;

    my $raw = $self->_raw_metadata( $self->_mmdb );

    my $metadata = MaxMind::DB::Metadata->new($raw);

    return $metadata unless $ENV{MAXMIND_DB_READER_DEBUG};

    $metadata->debug_dump;

    return $metadata;
}

## use critic

sub DEMOLISH {
    my $self = shift;

    $self->_close_mmdb( $self->_mmdb )
        if $self->_has_mmdb;

    return;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Fast XS implementation of MaxMind DB reader

__END__

=pod

=encoding UTF-8

=head1 NAME

MaxMind::DB::Reader::XS - Fast XS implementation of MaxMind DB reader

=head1 VERSION

version 1.000008

=head1 SYNOPSIS

    my $reader = MaxMind::DB::Reader->new( file => 'path/to/database.mmdb' );

    my $record = $reader->record_for_address('1.2.3.4');

=head1 DESCRIPTION

Simply installing this module causes L<MaxMind::DB::Reader> to use the XS
implementation, which is much faster than the Perl implementation.

The XS implementation links against the
L<libmaxminddb|http://maxmind.github.io/libmaxminddb/> library.

See L<MaxMind::DB::Reader> for API details.

=for Pod::Coverage BUILD DEMOLISH

=for :stopwords PPA

=head1 VERSIONING POLICY

This module uses semantic versioning as described by
L<http://semver.org/>. Version numbers can be read as X.YYYZZZ, where X is the
major number, YYY is the minor number, and ZZZ is the patch number.

=head1 MAC OS X SUPPORT

If you're running into install errors under Mac OS X, you may need to force a
build of the 64 bit binary. For example, if you're installing via C<cpanm>:

    ARCHFLAGS="-arch x86_64" cpanm MaxMind::DB::Reader::XS

=head1 UBUNTU SUPPORT

The version of libmaxminddb that is available by default with Ubuntu may be
too old for this level of MaxMind::DB::Reader::XS.  However, we do maintain a
Launchpad PPA for all supported levels of Ubuntu.

    https://launchpad.net/~maxmind/+archive/ubuntu/ppa

Please visit the PPA page for more information, or, to configure your system,
run as root:

    # apt-add-repository ppa:maxmind/ppa
    # apt-get update

The PPA is now configured, and you may install (or upgrade) the libmaxminddb
library via the usual apt commands.

=head1 SUPPORT

This module is deprecated and will only receive fixes for major bugs and
security vulnerabilities. New features and functionality will not be added.

Please report all issues with this code using the GitHub issue tracker at
L<https://github.com/maxmind/MaxMind-DB-Reader-XS/issues>.

Bugs may be submitted through L<https://github.com/maxmind/MaxMind-DB-Reader-XS/issues>.

=head1 AUTHORS

=over 4

=item *

Boris Zentner <bzentner@maxmind.com>

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

Ran Eilam <reilam@maxmind.com>

=back

=head1 CONTRIBUTORS

=for stopwords Andy Jack Chris Weyl Florian Ragwitz Greg Oschwald Hidenori Sugiyama Mark Fowler Olaf Alders

=over 4

=item *

Andy Jack <github@veracity.ca>

=item *

Chris Weyl <cweyl@alumni.drew.edu>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Greg Oschwald <goschwald@maxmind.com>

=item *

Hidenori Sugiyama <madogiwa@gmail.com>

=item *

Mark Fowler <mark@twoshortplanks.com>

=item *

Olaf Alders <oalders@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2019 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
