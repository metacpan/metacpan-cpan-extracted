#!perl -T
use warnings; use strict;
use Test::More tests => 10;
use Test::Warn;

=pod

These tests largely check some of the more subtle and easily broken edge
cases with different elluminate versions and deployment configurations

=cut

package main;

use Elive::Entity::Group;
use Elive::Entity::User;
use Elive::Entity::Recording;
use Elive::Entity::Report;
use Elive::Entity::MeetingParameters;
use Elive::Entity::ServerParameters;

#
# Group Ids can be non-numeric when configured to use LDAP for 
# group management
#
my $group_types = Elive::Entity::Group->property_types;
is($group_types->{groupId}, 'Str', 'non-numeric groupIds permitted (LDAP compat)');
ok($group_types->{domain}, 'group has domain property (early ELM 3.0 compat)');

#
# User Ids can be non-numeric when configured to use LDAP for 
# user management
#
my $report_types = Elive::Entity::Report->property_types;
is($report_types->{ownerId}, 'Str', 'non-numeric report ownerIds permitted (LDAP compat)');
my $user_types = Elive::Entity::User->property_types;
is($user_types->{userId}, 'Str', 'non-numeric userIds permitted (LDAP compat)');
#
# User 'domain' and 'group' were present in early ELM 3.x, but appear to be stillborn
#
ok($user_types->{domain}, 'user has domain property (early ELM 3.0 compat)');
ok($user_types->{groups}, 'user has groups property (early ELM 3.0 compat)');

#
# recording IDs can be user supplied and non-numeric
#
my $recording_types = Elive::Entity::Recording->property_types;
is($recording_types->{recordingId}, 'Str', "non-numeric recordingId's permitted");

#
# inSessionInvitation present in elm 9.0, but not 9.1?
#
my $meeting_parameter_types = Elive::Entity::MeetingParameters->property_types;
ok(exists $meeting_parameter_types->{inSessionInvitation},
   'inSessionInvitation declared for meeting parameters (9.0 compat)');

#
# some toolkit mispellings. required as long as we're supporting 9.x
#
my %to_aliases = Elive::Entity::ServerParameters->_to_aliases;
is( $to_aliases{modertatorTelephonyAddress} => 'moderatorTelephonyAddress', 'moderatorTelephonyAddress (sic)');
is( $to_aliases{modertatorTelephonyPIN} => 'moderatorTelephonyPIN', 'moderatorTelephonyPIN (sic)');
