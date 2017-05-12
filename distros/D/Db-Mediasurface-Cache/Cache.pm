package Db::Mediasurface::Cache;
$VERSION = 0.04;
use strict;
use Carp;

use constant VALUE => 0;
use constant COUNT => 1;

sub new {
    my ($class, %arg) = @_;
    my $self = { hits => 0,
		 size => 0,
		 maxsize => $arg{size},
		 hash => undef
		 };
    bless $self, $class;
}

sub get {
    my ($self, $key) = @_;
    return unless defined $key;
    return unless exists $self->{hash}->{$key};
    my $value = $self->{hash}->{$key}->[VALUE];
    if (defined $self->{maxsize}){
	$self->{hash}->{$key}->[COUNT]++;
	$self->{hits} ++;
    }
    return $value;
}

sub set {
    my ($self, $key, $value) = @_;
    return unless defined $key;
    if (exists $self->{hash}->{$key}){
	$self->{hash}->{$key}->[VALUE] = $value;
	$self->{hits} = $self->{hits} - $self->{hash}->{$key}->[COUNT];
	$self->{hash}->{$key}->[COUNT] = 0;
    } else {
	$self->{hash}->{$key}->[VALUE] = $value;
	$self->{hash}->{$key}->[COUNT] = 0;
	$self->{size} ++;
    }
    if ((defined $self->{maxsize}) && ($self->{size} >= $self->{maxsize})){
	my $cutoff = int($self->{hits} / $self->{size}) + 1;
	foreach my $test_key (keys %{$self->{hash}}){
	    if ( $self->{hash}->{$test_key}->[COUNT] > $cutoff ){
		$self->{hash}->{$test_key}->[COUNT] = 0;
	    } else {
		delete $self->{hash}->{$test_key};
		$self->{size} --;
	    }
	}
	$self->{hits} = 0;
    }
}

sub unset {
    my ($self,$key) = @_;
    return unless defined $key;
    return unless exists $self->{hash}->{$key};
    $self->{hits} = $self->{hits} - $self->{hash}->{$key}->[COUNT];
    delete $self->{hash}->{$key};
}

1;

=head1 NAME

Db::Mediasurface::Cache - caches a specified number of key-value pairs, disgarding underused pairs.

=head1 VERSION

This document refers to version 0.04 of DB::Mediasurface::Cache, released August 3, 2001.

=head1 SYNOPSIS

use Db::Mediasurface::Cache;

my $url = 'http://some.site.com/some/path?version=2';

my $id = undef;

my $cache = Db::Mediasurface::Cache->new( size => 1000 );

unless (defined ($id = $cache->get($url)))
{
    $id = urldecode2id($url);
    $cache->set($url,$id);
}

=head1 DESCRIPTION

=head2 Overview

Mediasurface relies on retrieving a unique ID for almost every object lookup. This module aims to cache url->id lookups in memory. The module allows commonly used key-value pairs to be stored towards the 'fresh' end of the store, and seldomly used pairs to drift towards the 'stale' end, from where they will eventually be pushed into oblivion, should the cache reach its maximum size. Basically, it's a trade-off between size and speed - the module will perform best when you need to perform lots of lookups of a wide range of urls, but the majority of lookups are contained within a much smaller subset of urls.

=head2 Constructor

=over 4

=item $cache = Db::Mediasurface::Cache->new(size=>1000);

This class method constructs a new cache. the size parameter can be used to set the maximum number of key-value pairs to be cached. If size is omitted, the cache defaults to using an infinite store, which has no protection from eating all your available RAM [NOTE: this is a change in behaviour from version 0.02].

=back

=head2 Methods

=over 4

=item $cache->set($key,$value)

Sets key-value pairs. [Note that this method can now only accept *one* key-value pair. This is a change of behaviour from version 0.03].

=item $id = $cache->get($key);

Gets the value of a given key. Returns the value, or undef if the key doesn't exist.

=item $cache->unset($key1);

Delete the key-value pair specified by the given key.

=back

=head1 AUTHOR

Nigel Wetters (nwetters@cpan.org)

=head1 COPYRIGHT

Copyright (c) 2001, Nigel Wetters. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

