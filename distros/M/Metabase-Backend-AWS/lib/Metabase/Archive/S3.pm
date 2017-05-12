use 5.006;
use strict;
use warnings;

package Metabase::Archive::S3;
our $VERSION = '1.000'; # VERSION

use Moose;
use namespace::autoclean;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class;
use namespace::autoclean;

use Metabase::Fact;
use Carp       ();
use Data::GUID ();
use Data::Stream::Bulk::Filter 0.08;
use JSON 2 ();
use Net::Amazon::S3;
use Path::Class ();
use Compress::Zlib 2 qw(compress uncompress);

with 'Metabase::Backend::AWS';
with 'Metabase::Archive' => { -version => 1.000 };

# Prefix string must have a trailing slash but not leading slash
subtype 'PrefixStr'
  => as 'Str'
  => where { $_ =~ m{^\w} && $_ =~ m{/$} };

coerce 'PrefixStr'
  => from 'Str' => via { s{/$}{}; s{^/}{}; $_ . "/" };

has 'bucket' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'prefix' => (
    is       => 'ro',
    isa      => 'PrefixStr',
    required => 1,
    coerce   => 1,
);

has 'compressed' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

has 's3_bucket' => (
    is       => 'ro',
    isa      => 'Net::Amazon::S3::Client::Bucket',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my $s3   = Net::Amazon::S3->new(
            aws_access_key_id     => $self->access_key_id,
            aws_secret_access_key => $self->secret_access_key,
            retry                 => 1,
        );
        my $client = Net::Amazon::S3::Client->new( s3 => $s3 );
        my $method = (grep { $_ eq $self->bucket } $client->buckets) ? 'bucket' : 'create_bucket';
        return $client->$method( name => $self->bucket );
    }
);

has '_json' => (
  is => 'ro',
  required => 1,
  lazy => 1,
  default => sub { JSON->new->ascii },
);

sub initialize {}

# given fact, store it and return guid;
sub store {
    my ( $self, $fact_struct ) = @_;
    my $guid = $fact_struct->{metadata}{core}{guid};
    my $type = $fact_struct->{metadata}{core}{type};

    unless ($guid) {
        Carp::confess "Can't store: no GUID set for fact\n";
    }

    my $json = $self->_json->encode($fact_struct);

    if ( $self->compressed ) {
        $json = compress($json);
    }

    my $s3_object = $self->s3_bucket->object(
        key          => $self->prefix . lc $guid,
#        acl_short    => 'public-read',
        content_type => 'application/json',
    );
    $s3_object->put($json);

    return $guid;
}

# given guid, retrieve it and return it
# type is directory path
# class isa Metabase::Fact::Subclass
sub extract {
    my ( $self, $guid ) = @_;

    my $s3_object = $self->s3_bucket->object( key => $self->prefix . lc $guid );
    return $self->_extract_struct( $s3_object );
}

sub _extract_struct {
  my ( $self, $s3_object ) = @_;

  my $json = $s3_object->get;
  if ( $self->compressed ) {
    $json = uncompress($json);
  }
  my $struct  = $self->_json->decode($json);
  return $struct;
}

# DO NOT lc() GUID
sub delete {
    my ( $self, $guid ) = @_;

    my $s3_object = $self->s3_bucket->object( key => $self->prefix . $guid );
    $s3_object->delete;
}

sub iterator {
  my ($self) = @_;
  return Data::Stream::Bulk::Filter->new(
    stream => $self->s3_bucket->list( { prefix => $self->prefix } ),
    filter => sub {
      return [ map { $self->_extract_struct( $_ ) } @{ $_[0] } ];
    },
  );
}

1;

# ABSTRACT: Metabase storage using Amazon S3
#
# This file is part of Metabase-Backend-AWS
#
# This software is Copyright (c) 2011 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#


__END__
=pod

=head1 NAME

Metabase::Archive::S3 - Metabase storage using Amazon S3

=head1 VERSION

version 1.000

=head1 SYNOPSIS

  require Metabase::Archive::S3;
  Metabase::Archive::S3->new(
    access_key_id => 'XXX',
    secret_access_key => 'XXX',
    bucket     => 'acme',
    prefix     => 'metabase/',
    compressed => 0,
  );

=head1 DESCRIPTION

This is an implementation of the L<Metabase::Archive> role using Amazon S3

=head1 ATTRIBUTES

=head2 bucket (required)

S3 bucket name to use for storage

=head2 prefix (required)

S3 prefix (within the bucket) to use for storage.  This should be unique
for each Metabase installation.

=head2 compressed (deprecated)

Boolean flag indicating whether facts should be compressed prior to S3
storage.  Once facts are stored compressed or not compressed,
this should not be changed for any given Metabase archive.

The default is now true and this attribute deprecated.  It remains to allow
access to older, uncompressed archives.

=for Pod::Coverage::TrustPod store extract delete iterator initialize

=head1 USAGE

See L<Metabase::Backend::AWS> for common constructor attributes and see below
for constructor attributes specific to this class.  See L<Metabase::Archive>
and L<Metabase::Librarian> for details on usage.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

