package Google::Monitoring::V3::Group;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CiBnb29nbGUvbW9uaXRvcmluZy92My9ncm91cC5wcm90bxIUZ29vZ2xlLm1vbml0b3Jpbmcu
djMaGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8isgIKBUdyb3VwEhIKBG5hbWUYASABKAlS
BG5hbWUSIQoMZGlzcGxheV9uYW1lGAIgASgJUgtkaXNwbGF5TmFtZRIfCgtwYXJlbnRfbmFt
ZRgDIAEoCVIKcGFyZW50TmFtZRIWCgZmaWx0ZXIYBSABKAlSBmZpbHRlchIdCgppc19jbHVz
dGVyGAYgASgIUglpc0NsdXN0ZXI6mQHqQZUBCh9tb25pdG9yaW5nLmdvb2dsZWFwaXMuY29t
L0dyb3VwEiFwcm9qZWN0cy97cHJvamVjdH0vZ3JvdXBzL3tncm91cH0SK29yZ2FuaXphdGlv
bnMve29yZ2FuaXphdGlvbn0vZ3JvdXBzL3tncm91cH0SH2ZvbGRlcnMve2ZvbGRlcn0vZ3Jv
dXBzL3tncm91cH0SASpCxQEKGGNvbS5nb29nbGUubW9uaXRvcmluZy52M0IKR3JvdXBQcm90
b1ABWkFjbG91ZC5nb29nbGUuY29tL2dvL21vbml0b3JpbmcvYXBpdjMvdjIvbW9uaXRvcmlu
Z3BiO21vbml0b3JpbmdwYqoCGkdvb2dsZS5DbG91ZC5Nb25pdG9yaW5nLlYzygIaR29vZ2xl
XENsb3VkXE1vbml0b3JpbmdcVjPqAh1Hb29nbGU6OkNsb3VkOjpNb25pdG9yaW5nOjpWM0q/
GgoGEgQOAFkBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAd
CgkKAgMAEgMSACMKCAoBCBIDFAA3CgkKAgglEgMUADcKCAoBCBIDFQBYCgkKAggLEgMVAFgK
CAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwArCgkKAggIEgMXACsKCAoBCBIDGAAxCgkK
AggBEgMYADEKCAoBCBIDGQA3CgkKAggpEgMZADcKCAoBCBIDGgA2CgkKAggtEgMaADYK7wsK
AgQAEgQ2AFkBGuILIFRoZSBkZXNjcmlwdGlvbiBvZiBhIGR5bmFtaWMgY29sbGVjdGlvbiBv
ZiBtb25pdG9yZWQgcmVzb3VyY2VzLiBFYWNoIGdyb3VwCiBoYXMgYSBmaWx0ZXIgdGhhdCBp
cyBtYXRjaGVkIGFnYWluc3QgbW9uaXRvcmVkIHJlc291cmNlcyBhbmQgdGhlaXIgYXNzb2Np
YXRlZAogbWV0YWRhdGEuIElmIGEgZ3JvdXAncyBmaWx0ZXIgbWF0Y2hlcyBhbiBhdmFpbGFi
bGUgbW9uaXRvcmVkIHJlc291cmNlLCB0aGVuCiB0aGF0IHJlc291cmNlIGlzIGEgbWVtYmVy
IG9mIHRoYXQgZ3JvdXAuICBHcm91cHMgY2FuIGNvbnRhaW4gYW55IG51bWJlciBvZgogbW9u
aXRvcmVkIHJlc291cmNlcywgYW5kIGVhY2ggbW9uaXRvcmVkIHJlc291cmNlIGNhbiBiZSBh
IG1lbWJlciBvZiBhbnkKIG51bWJlciBvZiBncm91cHMuCgogR3JvdXBzIGNhbiBiZSBuZXN0
ZWQgaW4gcGFyZW50LWNoaWxkIGhpZXJhcmNoaWVzLiBUaGUgYHBhcmVudE5hbWVgIGZpZWxk
CiBpZGVudGlmaWVzIGFuIG9wdGlvbmFsIHBhcmVudCBmb3IgZWFjaCBncm91cC4gIElmIGEg
Z3JvdXAgaGFzIGEgcGFyZW50LCB0aGVuCiB0aGUgb25seSBtb25pdG9yZWQgcmVzb3VyY2Vz
IGF2YWlsYWJsZSB0byBiZSBtYXRjaGVkIGJ5IHRoZSBncm91cCdzIGZpbHRlcgogYXJlIHRo
ZSByZXNvdXJjZXMgY29udGFpbmVkIGluIHRoZSBwYXJlbnQgZ3JvdXAuICBJbiBvdGhlciB3
b3JkcywgYSBncm91cAogY29udGFpbnMgdGhlIG1vbml0b3JlZCByZXNvdXJjZXMgdGhhdCBt
YXRjaCBpdHMgZmlsdGVyIGFuZCB0aGUgZmlsdGVycyBvZiBhbGwKIHRoZSBncm91cCdzIGFu
Y2VzdG9ycy4gIEEgZ3JvdXAgd2l0aG91dCBhIHBhcmVudCBjYW4gY29udGFpbiBhbnkgbW9u
aXRvcmVkCiByZXNvdXJjZS4KCiBGb3IgZXhhbXBsZSwgY29uc2lkZXIgYW4gaW5mcmFzdHJ1
Y3R1cmUgcnVubmluZyBhIHNldCBvZiBpbnN0YW5jZXMgd2l0aCB0d28KIHVzZXItZGVmaW5l
ZCB0YWdzOiBgImVudmlyb25tZW50ImAgYW5kIGAicm9sZSJgLiBBIHBhcmVudCBncm91cCBo
YXMgYSBmaWx0ZXIsCiBgZW52aXJvbm1lbnQ9InByb2R1Y3Rpb24iYC4gIEEgY2hpbGQgb2Yg
dGhhdCBwYXJlbnQgZ3JvdXAgaGFzIGEgZmlsdGVyLAogYHJvbGU9InRyYW5zY29kZXIiYC4g
IFRoZSBwYXJlbnQgZ3JvdXAgY29udGFpbnMgYWxsIGluc3RhbmNlcyBpbiB0aGUKIHByb2R1
Y3Rpb24gZW52aXJvbm1lbnQsIHJlZ2FyZGxlc3Mgb2YgdGhlaXIgcm9sZXMuICBUaGUgY2hp
bGQgZ3JvdXAgY29udGFpbnMKIGluc3RhbmNlcyB0aGF0IGhhdmUgdGhlIHRyYW5zY29kZXIg
cm9sZSAqYW5kKiBhcmUgaW4gdGhlIHByb2R1Y3Rpb24KIGVudmlyb25tZW50LgoKIFRoZSBt
b25pdG9yZWQgcmVzb3VyY2VzIGNvbnRhaW5lZCBpbiBhIGdyb3VwIGNhbiBjaGFuZ2UgYXQg
YW55IG1vbWVudCwKIGRlcGVuZGluZyBvbiB3aGF0IHJlc291cmNlcyBleGlzdCBhbmQgd2hh
dCBmaWx0ZXJzIGFyZSBhc3NvY2lhdGVkIHdpdGggdGhlCiBncm91cCBhbmQgaXRzIGFuY2Vz
dG9ycy4KCgoKAwQAARIDNggNCgsKAwQABxIENwI9BAoNCgUEAAedCBIENwI9BArCAgoEBAAC
ABIDRgISGrQCIE91dHB1dCBvbmx5LiBUaGUgbmFtZSBvZiB0aGlzIGdyb3VwLiBUaGUgZm9y
bWF0IGlzOgoKICAgICBwcm9qZWN0cy9bUFJPSkVDVF9JRF9PUl9OVU1CRVJdL2dyb3Vwcy9b
R1JPVVBfSURdCgogV2hlbiBjcmVhdGluZyBhIGdyb3VwLCB0aGlzIGZpZWxkIGlzIGlnbm9y
ZWQgYW5kIGEgbmV3IG5hbWUgaXMgY3JlYXRlZAogY29uc2lzdGluZyBvZiB0aGUgcHJvamVj
dCBzcGVjaWZpZWQgaW4gdGhlIGNhbGwgdG8gYENyZWF0ZUdyb3VwYAogYW5kIGEgdW5pcXVl
IGBbR1JPVVBfSURdYCB0aGF0IGlzIGdlbmVyYXRlZCBhdXRvbWF0aWNhbGx5LgoKDAoFBAAC
AAUSA0YCCAoMCgUEAAIAARIDRgkNCgwKBQQAAgADEgNGEBEKUwoEBAACARIDSQIaGkYgQSB1
c2VyLWFzc2lnbmVkIG5hbWUgZm9yIHRoaXMgZ3JvdXAsIHVzZWQgb25seSBmb3IgZGlzcGxh
eSBwdXJwb3Nlcy4KCgwKBQQAAgEFEgNJAggKDAoFBAACAQESA0kJFQoMCgUEAAIBAxIDSRgZ
CssBCgQEAAICEgNQAhkavQEgVGhlIG5hbWUgb2YgdGhlIGdyb3VwJ3MgcGFyZW50LCBpZiBp
dCBoYXMgb25lLiBUaGUgZm9ybWF0IGlzOgoKICAgICBwcm9qZWN0cy9bUFJPSkVDVF9JRF9P
Ul9OVU1CRVJdL2dyb3Vwcy9bR1JPVVBfSURdCgogRm9yIGdyb3VwcyB3aXRoIG5vIHBhcmVu
dCwgYHBhcmVudF9uYW1lYCBpcyB0aGUgZW1wdHkgc3RyaW5nLCBgIiJgLgoKDAoFBAACAgUS
A1ACCAoMCgUEAAICARIDUAkUCgwKBQQAAgIDEgNQFxgKXAoEBAACAxIDVAIUGk8gVGhlIGZp
bHRlciB1c2VkIHRvIGRldGVybWluZSB3aGljaCBtb25pdG9yZWQgcmVzb3VyY2VzIGJlbG9u
ZyB0byB0aGlzCiBncm91cC4KCgwKBQQAAgMFEgNUAggKDAoFBAACAwESA1QJDwoMCgUEAAID
AxIDVBITCpsBCgQEAAIEEgNYAhYajQEgSWYgdHJ1ZSwgdGhlIG1lbWJlcnMgb2YgdGhpcyBn
cm91cCBhcmUgY29uc2lkZXJlZCB0byBiZSBhIGNsdXN0ZXIuCiBUaGUgc3lzdGVtIGNhbiBw
ZXJmb3JtIGFkZGl0aW9uYWwgYW5hbHlzaXMgb24gZ3JvdXBzIHRoYXQgYXJlIGNsdXN0ZXJz
LgoKDAoFBAACBAUSA1gCBgoMCgUEAAIEARIDWAcRCgwKBQQAAgQDEgNYFBViBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::V3::Group::Group ===
    # Fields for Group
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: parent_name Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: is_cluster Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::V3::Group - Compiled Protocol Buffers messages for google/monitoring/v3/group.proto

=head1 SYNOPSIS

    use Google::Monitoring::V3::Group;

    my $msg = Google::Monitoring::V3::Group::Group->new({
        name => $name,
        display_name => $display_name,
        parent_name => $parent_name,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::V3::Group::Group->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/v3/group.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::V3::Group::Group

The description of a dynamic collection of monitored resources. Each group
has a filter that is matched against monitored resources and their associated
metadata. If a group's filter matches an available monitored resource, then
that resource is a member of that group.  Groups can contain any number of
monitored resources, and each monitored resource can be a member of any
number of groups.

Groups can be nested in parent-child hierarchies. The `parentName` field
identifies an optional parent for each group.  If a group has a parent, then
the only monitored resources available to be matched by the group's filter
are the resources contained in the parent group.  In other words, a group
contains the monitored resources that match its filter and the filters of all
the group's ancestors.  A group without a parent can contain any monitored
resource.

For example, consider an infrastructure running a set of instances with two
user-defined tags: `"environment"` and `"role"`. A parent group has a filter,
`environment="production"`.  A child of that parent group has a filter,
`role="transcoder"`.  The parent group contains all instances in the
production environment, regardless of their roles.  The child group contains
instances that have the transcoder role *and* are in the production
environment.

The monitored resources contained in a group can change at any moment,
depending on what resources exist and what filters are associated with the
group and its ancestors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of this group. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/groups/[GROUP_ID]

When creating a group, this field is ignored and a new name is created
consisting of the project specified in the call to `CreateGroup`
and a unique `[GROUP_ID]` that is generated automatically.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

A user-assigned name for this group, used only for display purposes.

=item * C<< $msg->parent_name() >> / C<< $msg->parent_name($value) >>

Type: C<String>

The name of the group's parent, if it has one. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/groups/[GROUP_ID]

For groups with no parent, `parent_name` is the empty string, `""`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

The filter used to determine which monitored resources belong to this
group.

=item * C<< $msg->is_cluster() >> / C<< $msg->is_cluster($value) >>

Type: C<Bool>

If true, the members of this group are considered to be a cluster.
The system can perform additional analysis on groups that are clusters.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::V3::Group::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
