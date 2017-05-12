# $Id: /mirror/perl/GunghoX-FollowLinks/trunk/lib/GunghoX/FollowLinks/Rule/Allow.pm 8894 2007-11-10T15:15:07.379456Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package GunghoX::FollowLinks::Rule::Allow;
use strict;
use warnings;
use base qw(GunghoX::FollowLinks::Rule);

sub apply { &GunghoX::FollowLinks::Rule::FOLLOW_ALLOW }

1;

__END__

=head1 NAME

GunghoX::FollowLinks::Rule::Allow - Always Allow

=head1 DESCRIPTION

If you specify this rule, it will always allow a link to be followed.

=head1 METHODS

=head2 apply

Always returns true

=cut