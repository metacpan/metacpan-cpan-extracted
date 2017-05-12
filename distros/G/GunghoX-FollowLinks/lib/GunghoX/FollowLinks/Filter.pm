# $Id: /mirror/perl/GunghoX-FollowLinks/trunk/lib/GunghoX/FollowLinks/Filter.pm 40578 2008-01-29T05:45:09.689971Z daisuke  $

package GunghoX::FollowLinks::Filter;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

sub new { shift->SUPER::new({ @_ }) }

sub apply {}

1;

__END__

=head1 NAME

Gunghox::FollowLinks::Filter - Filter URI

=head1 METHODS

=head2 apply

=cut
