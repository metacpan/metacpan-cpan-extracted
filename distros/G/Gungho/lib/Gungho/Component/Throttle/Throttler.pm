# $Id: /mirror/gungho/lib/Gungho/Component/Throttle/Throttler.pm 3224 2007-10-10T08:08:59.964068Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::Throttle::Throttler;
use strict;
use warnings;
use base qw(Gungho::Component::Throttle);

__PACKAGE__->mk_classdata($_) for qw(throttler);

sub prepare_throttler
{
    my $self = shift;
    my %args = @_;

    my $class = delete $args{throttler} || 'Data::Throttler';
    if (! Class::Inspector->loaded($class)) {
        $class->require or die;
    }

    $args{max_items} ||= 1000;
    $args{interval}  ||= 3600;

    $self->throttler( $class->new( %args ) );
}

1;

__END__

=head1 NAME

Gungho::Component::Throttle::Throttler - Data::Throttler Based Throttling

=head1 SYNOPSIS

  # Internal use only

=head1 METHODS

=head2 prepare_throttler(%args)

=cut
