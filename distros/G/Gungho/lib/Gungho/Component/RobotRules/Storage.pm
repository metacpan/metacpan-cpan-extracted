# $Id: /mirror/gungho/lib/Gungho/Component/RobotRules/Storage.pm 31135 2007-11-27T02:16:34.769889Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package Gungho::Component::RobotRules::Storage;
use strict;
use warnings;
use base qw(Gungho::Base);

__PACKAGE__->mk_accessors($_) for qw(storage);
__PACKAGE__->mk_virtual_methods($_) for qw(get_rule put_rule get_pending_robots_txt push_pending_robots_txt);

1;

__END__

=head1 NAME

Gungho::Component::RobotRules::Storage - RobotRules Storage Base Class

=head1 METHODS

=head2 storage

Holds the actual storage backend

=head2 get_rule

Gets a rule for a particular URL

=head2 put_rule

Stores a rule for a particular URL

=head2 get_pending_robots_txt

Returns a list of requests that were waiting for that particular robots.txt
information

=head2 push_pending_robots_txt

Adds a request to the list of requests waiting for a particular robots.txt
information

=cut
