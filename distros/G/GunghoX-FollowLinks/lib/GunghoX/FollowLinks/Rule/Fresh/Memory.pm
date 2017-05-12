# $Id: /mirror/perl/GunghoX-FollowLinks/trunk/lib/GunghoX/FollowLinks/Rule/Fresh/Memory.pm 31640 2007-12-01T15:48:28.904993Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package GunghoX::FollowLinks::Rule::Fresh::Memory;
use strict;
use warnings;

sub new
{
    my $class = shift;
    return bless { seen => {} }, $class;
}

sub put
{
    my ($self, $url) = @_;
    $self->{seen}{$url}++;
}

sub get
{
    my ($self, $url) = @_;
    return $self->{seen}{$url};
}

1;

__END__

=head1 NAME 

GunghoX::FollowLinks::Rule::Fresh::Memory - Store URLs In Memory

=head1 METHODS

=head2 new

=head2 put

=head2 get

=cut
