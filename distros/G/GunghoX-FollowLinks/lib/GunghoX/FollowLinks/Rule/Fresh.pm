# $Id: /mirror/perl/GunghoX-FollowLinks/trunk/lib/GunghoX/FollowLinks/Rule/Fresh.pm 40501 2008-01-24T04:48:27.359921Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package GunghoX::FollowLinks::Rule::Fresh;
use strict;
use warnings;
use Gungho::Util;
use GunghoX::FollowLinks::Rule qw(FOLLOW_ALLOW FOLLOW_DENY);
use base qw(GunghoX::FollowLinks::Rule);

__PACKAGE__->mk_accessors($_) for qw(storage);

sub new
{
    my $class   = shift;
    my %args    = @_;

    my $storage_config = delete $args{storage};
    my $storage_module = Gungho::Util::load_module(
        $storage_config->{module} || 'Memory',
        'GunghoX::FollowLinks::Rule::Fresh'
    );
    my $storage = $storage_module->new( %{ $storage_config->{config} || {} } );
    
    $class->next::method(storage => $storage);
}

sub apply
{
    my ($self, $c, $response, $url, $attrs) = @_;

    my $storage = $self->storage;
    if ($storage->get($url->as_string)) {
        return FOLLOW_DENY;
    } else {
        $storage->put($url->as_string);
        return FOLLOW_ALLOW;
    }
}

1;

__END__

=head1 NAME

GunghoX::FollowLinks::Rule::Fresh - Only Follow Fresh Links

=head1 SYNOPSIS

  use GunghoX::FollowLinks::Rule::Fresh;
  my $rule = GunghoX::FollowLinks::Rule::Fresh->new(
    storage => {
      module => "Memory",
    }
  );
  $rule->apply( $c, $response, $url, $attrs );

=head1 DESCRIPTION

This rule allows you to follow links thatyou haven't seen yet. The list of
URLs that have been fetched are stored in a storage module of your choise.

If you want to put it in a memcached instance, for example, you can specify
it like this:

  my $rule = GunghoX::FollowLinks::Rule::Fresh->new(
    storage => {
      module => "Cache",
      config => {
        cache => {
          module => "Cache::Memcached",
          config => {
            servers => "127.0.0.1:11211",
            compress_threshold => 10_000,
          }
        }
      }
    }
  );
  
=head1 METHODS

=head2 new

Creates a new rule instance. You must specify the storage backend.

=head2 apply

Applies the rule.

=cut