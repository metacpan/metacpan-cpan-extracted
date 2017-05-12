# $Id: /mirror/perl/GunghoX-FollowLinks/trunk/lib/GunghoX/FollowLinks/Rule.pm 8918 2007-11-12T03:02:15.291385Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package GunghoX::FollowLinks::Rule;
use strict;
use warnings;
use base qw(Gungho::Base);

use Sub::Exporter -setup => {
    exports => [ qw(FOLLOW_ALLOW FOLLOW_DENY FOLLOW_DEFER) ]
};
use constant FOLLOW_ALLOW => "FOLLOW_ALLOW";
use constant FOLLOW_DENY  => "FOLLOW_DENY";
use constant FOLLOW_DEFER => "FOLLOW_DEFER";

sub apply { die "You must override apply()" }

1;

__END__

=head1 NAME

GunghoX::FollowLinks::Rule - Rule To Decide If A Link Should Be Followed

=head1 SYNOPSIS

  use GunghoX::FollowLinks::Rule q(FOLLOW_ALLOW FOLLOW_DENY FOLLOW_DEFER);

  package MyRule;
  use base qw(GunghoX::FollowLinks::Rule);

  sub apply {
    # custom logic
  }

=head1 CONSTANTS

=head2 FOLLOW_ALLOW

=head2 FOLLOW_DENY

=head2 FOLLOW_DEFER

=head1 METHODS

=head2 apply

Subclasses must override this method. The exact arguments change depending
on the GunghoX::FollowLinks::Parser object being used, but the first two
elements are always the global Gungho context and the Gungho::Response
object.

=cut
