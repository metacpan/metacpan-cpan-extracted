# $Id: /mirror/perl/GunghoX-FollowLinks/trunk/lib/GunghoX/FollowLinks/Rule/Fresh/Cache.pm 40502 2008-01-24T04:50:29.650533Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package GunghoX::FollowLinks::Rule::Fresh::Cache;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(cache _memcached_managed_hack);

sub new
{
    my $class = shift;
    my %args  = @_;

    my $cache_config = delete $args{cache};
    my $cache_module = Gungho::Util::load_module(
        $cache_config->{module} || die "No cache module specified"
    );
        
    my $hashref = delete $cache_config->{config}->{hashref};
    my %cache_args = %{ $cache_config->{config} || {} } ;
    my $cache = $cache_module->new( $hashref ? \%cache_args : %cache_args);
    return bless {
        cache => $cache,
        _memcached_managed_hack => $cache->isa('Cache::Memcached::Managed'),
    }, $class;
}

sub put
{
    my ($self, $url) = @_;

    if ($self->_memcached_managed_hack) {
        $self->cache->set(1, $url);
    } else {
        $self->cache->set($url, 1);
    }
}

sub get
{
    my ($self, $url) = @_;

    $self->cache->get($url);
}

1;

__END__

=head1 NAME 

GunghoX::FollowLinks::Rule::Fresh::Cache - Store URLs In A Cache Of Your Choice

=head1 SYNOPSIS

  GunghoX::FollowLinks::Rule::Fresh->new(
    storage => {
      module => "Cache",
      config => {
        cache => {
          module => "Cache::Memcached",
          config => {
            hashref => 1,
            servers => [ '127.0.0.1:11211' ]
          }
        }
      }
    }
  );

=head1 METHODS

=head2 new

=head2 put

=head2 get

=cut