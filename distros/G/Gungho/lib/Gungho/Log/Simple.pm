# $Id: /mirror/gungho/lib/Gungho/Log/Simple.pm 4214 2007-10-29T04:36:39.100346Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Log::Simple;
use strict;
use warnings;
use base qw(Gungho::Log::Dispatch);

sub new
{
    my $self   = shift;
    my %args   = @_;
    my $config = $args{config};
    if (ref $config->{logs} ne 'HASH') {
        $config->{logs} = {};
    }

    $config->{logs}{module} = 'Screen';
    $config->{logs}{name}   = 'simple';
    $self->next::method(%args);
}

1;

__END__

=head1 NAME

Gungho::Log::Simple - Simple Gungho Log Class

=head1 SYNOPSIS

  use Gungho::Log::Simple;

  my $log = Gungho::Log::Simple->new();
  $log->setup($c,);

=head1 DESCRIPTION

This is a simple logger, which only logs to stderr.

=head1 METHODS

=head2 new

=cut