package Google::Firestore::Admin::V1::Snapshot;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxL3NuYXBzaG90LnByb3RvEhlnb29nbGUuZmly
ZXN0b3JlLmFkbWluLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3Rv
IsMBCgxQaXRyU25hcHNob3QSRQoIZGF0YWJhc2UYASABKAlCKeBBAvpBIwohZmlyZXN0b3Jl
Lmdvb2dsZWFwaXMuY29tL0RhdGFiYXNlUghkYXRhYmFzZRImCgxkYXRhYmFzZV91aWQYAiAB
KAxCA+BBA1ILZGF0YWJhc2VVaWQSRAoNc25hcHNob3RfdGltZRgDIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBCA+BBAlIMc25hcHNob3RUaW1lQuABCh1jb20uZ29vZ2xlLmZp
cmVzdG9yZS5hZG1pbi52MUIRUGl0clNuYXBzaG90UHJvdG9QAVo5Y2xvdWQuZ29vZ2xlLmNv
bS9nby9maXJlc3RvcmUvYXBpdjEvYWRtaW4vYWRtaW5wYjthZG1pbnBiogIER0NGU6oCH0dv
b2dsZS5DbG91ZC5GaXJlc3RvcmUuQWRtaW4uVjHKAh9Hb29nbGVcQ2xvdWRcRmlyZXN0b3Jl
XEFkbWluXFYx6gIjR29vZ2xlOjpDbG91ZDo6RmlyZXN0b3JlOjpBZG1pbjo6VjFKiQ0KBhIE
DgA0AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIgoJCgID
ABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWADwKCQoCCCUSAxYAPAoICgEI
EgMXAFAKCQoCCAsSAxcAUAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADIKCQoCCAgS
AxkAMgoICgEIEgMaADYKCQoCCAESAxoANgoICgEIEgMbACIKCQoCCCQSAxsAIgoICgEIEgMc
AD0KCQoCCCkSAxwAPQoICgEIEgMdADwKCQoCCC0SAx0APArYAgoCBAASBCQANAEaywIgQSBj
b25zaXN0ZW50IHNuYXBzaG90IG9mIGEgZGF0YWJhc2UgYXQgYSBzcGVjaWZpYyBwb2ludCBp
biB0aW1lLgogQSBQSVRSIChQb2ludC1pbi10aW1lIHJlY292ZXJ5KSBzbmFwc2hvdCB3aXRo
IHByZXZpb3VzIHZlcnNpb25zIG9mIGEKIGRhdGFiYXNlJ3MgZGF0YSBpcyBhdmFpbGFibGUg
Zm9yIGV2ZXJ5IG1pbnV0ZSB1cCB0byB0aGUgYXNzb2NpYXRlZCBkYXRhYmFzZSdzCiBkYXRh
IHJldGVudGlvbiBwZXJpb2QuIElmIHRoZSBQSVRSIGZlYXR1cmUgaXMgZW5hYmxlZCwgdGhl
IHJldGVudGlvbiBwZXJpb2QKIGlzIDcgZGF5czsgb3RoZXJ3aXNlLCBpdCBpcyBvbmUgaG91
ci4KCgoKAwQAARIDJAgUCoMBCgQEAAIAEgQnAiwEGnUgUmVxdWlyZWQuIFRoZSBuYW1lIG9m
IHRoZSBkYXRhYmFzZSB0aGF0IHRoaXMgd2FzIGEgc25hcHNob3Qgb2YuIEZvcm1hdDoKIGBw
cm9qZWN0cy97cHJvamVjdH0vZGF0YWJhc2VzL3tkYXRhYmFzZX1gLgoKDAoFBAACAAUSAycC
CAoMCgUEAAIAARIDJwkRCgwKBQQAAgADEgMnFBUKDQoFBAACAAgSBCcWLAMKDwoIBAACAAic
CAASAygEKgoPCgcEAAIACJ8IEgQpBCsFClkKBAQAAgESAy8CRRpMIE91dHB1dCBvbmx5LiBQ
dWJsaWMgVVVJRCBvZiB0aGUgZGF0YWJhc2UgdGhlIHNuYXBzaG90IHdhcyBhc3NvY2lhdGVk
IHdpdGguCgoMCgUEAAIBBRIDLwIHCgwKBQQAAgEBEgMvCBQKDAoFBAACAQMSAy8XGAoMCgUE
AAIBCBIDLxlECg8KCAQAAgEInAgAEgMvGkMKOAoEBAACAhIEMgIzLxoqIFJlcXVpcmVkLiBT
bmFwc2hvdCB0aW1lIG9mIHRoZSBkYXRhYmFzZS4KCgwKBQQAAgIGEgMyAhsKDAoFBAACAgES
AzIcKQoMCgUEAAICAxIDMiwtCgwKBQQAAgIIEgMzBi4KDwoIBAACAgicCAASAzMHLWIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::Admin::V1::Snapshot::PitrSnapshot ===
    # Fields for PitrSnapshot
    # Field: database Type: 9 ()
    # Field: database_uid Type: 12 ()
    # Field: snapshot_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::Admin::V1::Snapshot - Compiled Protocol Buffers messages for google/firestore/admin/v1/snapshot.proto

=head1 SYNOPSIS

    use Google::Firestore::Admin::V1::Snapshot;

    my $msg = Google::Firestore::Admin::V1::Snapshot::PitrSnapshot->new({
        database => $database,
        database_uid => $database_uid,
        snapshot_time => $snapshot_time,
    });

    # Read or update a field
    my $val = $msg->database();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::Admin::V1::Snapshot::PitrSnapshot->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/admin/v1/snapshot.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::Admin::V1::Snapshot::PitrSnapshot

A consistent snapshot of a database at a specific point in time.
A PITR (Point-in-time recovery) snapshot with previous versions of a
database's data is available for every minute up to the associated database's
data retention period. If the PITR feature is enabled, the retention period
is 7 days; otherwise, it is one hour.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->database() >> / C<< $msg->database($value) >>

Type: C<String>

Required. The name of the database that this was a snapshot of. Format:
`projects/{project}/databases/{database}`.

=item * C<< $msg->database_uid() >> / C<< $msg->database_uid($value) >>

Type: C<Bytes>

Output only. Public UUID of the database the snapshot was associated with.

=item * C<< $msg->snapshot_time() >> / C<< $msg->snapshot_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. Snapshot time of the database.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::Admin::V1::Snapshot::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
