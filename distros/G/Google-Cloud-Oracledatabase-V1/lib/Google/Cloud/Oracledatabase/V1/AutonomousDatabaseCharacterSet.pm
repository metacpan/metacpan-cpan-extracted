package Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet;

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
    my $descriptor_b64 = <<'EOF';
CkZnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvYXV0b25vbW91c19kYXRhYmFzZV9j
aGFyYWN0ZXJfc2V0LnByb3RvEh5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEaH2dv
b2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJv
dG8irwQKHkF1dG9ub21vdXNEYXRhYmFzZUNoYXJhY3RlclNldBIXCgRuYW1lGAEgASgJQgPg
QQhSBG5hbWUSggEKEmNoYXJhY3Rlcl9zZXRfdHlwZRgCIAEoDjJPLmdvb2dsZS5jbG91ZC5v
cmFjbGVkYXRhYmFzZS52MS5BdXRvbm9tb3VzRGF0YWJhc2VDaGFyYWN0ZXJTZXQuQ2hhcmFj
dGVyU2V0VHlwZUID4EEDUhBjaGFyYWN0ZXJTZXRUeXBlEigKDWNoYXJhY3Rlcl9zZXQYAyAB
KAlCA+BBA1IMY2hhcmFjdGVyU2V0IlIKEENoYXJhY3RlclNldFR5cGUSIgoeQ0hBUkFDVEVS
X1NFVF9UWVBFX1VOU1BFQ0lGSUVEEAASDAoIREFUQUJBU0UQARIMCghOQVRJT05BTBACOvAB
6kHsAQo8b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vQXV0b25vbW91c0RhdGFiYXNl
Q2hhcmFjdGVyU2V0Emtwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
YXV0b25vbW91c0RhdGFiYXNlQ2hhcmFjdGVyU2V0cy97YXV0b25vbW91c19kYXRhYmFzZV9j
aGFyYWN0ZXJfc2V0fSofYXV0b25vbW91c0RhdGFiYXNlQ2hhcmFjdGVyU2V0czIeYXV0b25v
bW91c0RhdGFiYXNlQ2hhcmFjdGVyU2V0Qv0BCiJjb20uZ29vZ2xlLmNsb3VkLm9yYWNsZWRh
dGFiYXNlLnYxQiNBdXRvbm9tb3VzRGF0YWJhc2VDaGFyYWN0ZXJTZXRQcm90b1ABWkpjbG91
ZC5nb29nbGUuY29tL2dvL29yYWNsZWRhdGFiYXNlL2FwaXYxL29yYWNsZWRhdGFiYXNlcGI7
b3JhY2xlZGF0YWJhc2VwYqoCHkdvb2dsZS5DbG91ZC5PcmFjbGVEYXRhYmFzZS5WMcoCHkdv
b2dsZVxDbG91ZFxPcmFjbGVEYXRhYmFzZVxWMeoCIUdvb2dsZTo6Q2xvdWQ6Ok9yYWNsZURh
dGFiYXNlOjpWMUqzDwoGEgQOAD8BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVADsKCQoCCCUSAxUA
OwoICgEIEgMWAGEKCQoCCAsSAxYAYQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAEQK
CQoCCAgSAxgARAoICgEIEgMZADsKCQoCCAESAxkAOwoICgEIEgMaADsKCQoCCCkSAxoAOwoI
CgEIEgMbADoKCQoCCC0SAxsAOgqpAQoCBAASBB8APwEanAEgRGV0YWlscyBvZiB0aGUgQXV0
b25vbW91cyBEYXRhYmFzZSBjaGFyYWN0ZXIgc2V0IHJlc291cmNlLgogaHR0cHM6Ly9kb2Nz
Lm9yYWNsZS5jb20vZW4tdXMvaWFhcy9hcGkvIy9lbi9kYXRhYmFzZS8yMDE2MDkxOC9BdXRv
bm9tb3VzRGF0YWJhc2VDaGFyYWN0ZXJTZXRzLwoKCgoDBAABEgMfCCYKCwoDBAAHEgQgAiUE
Cg0KBQQAB50IEgQgAiUECkoKBAQABAASBCgCMQMaPCBUaGUgdHlwZSBvZiBjaGFyYWN0ZXIg
c2V0IGFuIEF1dG9ub21vdXMgRGF0YWJhc2UgY2FuIGhhdmUuCgoMCgUEAAQAARIDKAcXCjUK
BgQABAACABIDKgQnGiYgQ2hhcmFjdGVyIHNldCB0eXBlIGlzIG5vdCBzcGVjaWZpZWQuCgoO
CgcEAAQAAgABEgMqBCIKDgoHBAAEAAIAAhIDKiUmCjcKBgQABAACARIDLQQRGiggQ2hhcmFj
dGVyIHNldCB0eXBlIGlzIHNldCB0byBkYXRhYmFzZS4KCg4KBwQABAACAQESAy0EDAoOCgcE
AAQAAgECEgMtDxAKNwoGBAAEAAICEgMwBBEaKCBDaGFyYWN0ZXIgc2V0IHR5cGUgaXMgc2V0
IHRvIG5hdGlvbmFsLgoKDgoHBAAEAAICARIDMAQMCg4KBwQABAACAgISAzAPEArbAQoEBAAC
ABIDNgI9Gs0BIElkZW50aWZpZXIuIFRoZSBuYW1lIG9mIHRoZSBBdXRvbm9tb3VzIERhdGFi
YXNlIENoYXJhY3RlciBTZXQgcmVzb3VyY2UgaW4KIHRoZSBmb2xsb3dpbmcgZm9ybWF0Ogog
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97cmVnaW9ufS9hdXRvbm9tb3VzRGF0YWJh
c2VDaGFyYWN0ZXJTZXRzL3thdXRvbm9tb3VzX2RhdGFiYXNlX2NoYXJhY3Rlcl9zZXR9CgoM
CgUEAAIABRIDNgIICgwKBQQAAgABEgM2CQ0KDAoFBAACAAMSAzYQEQoMCgUEAAIACBIDNhI8
Cg8KCAQAAgAInAgAEgM2EzsKUAoEBAACARIEOQI6MhpCIE91dHB1dCBvbmx5LiBUaGUgY2hh
cmFjdGVyIHNldCB0eXBlIGZvciB0aGUgQXV0b25vbW91cyBEYXRhYmFzZS4KCgwKBQQAAgEG
EgM5AhIKDAoFBAACAQESAzkTJQoMCgUEAAIBAxIDOSgpCgwKBQQAAgEIEgM6BjEKDwoIBAAC
AQicCAASAzoHMAp1CgQEAAICEgM+AkcaaCBPdXRwdXQgb25seS4gVGhlIGNoYXJhY3RlciBz
ZXQgbmFtZSBmb3IgdGhlIEF1dG9ub21vdXMgRGF0YWJhc2Ugd2hpY2ggaXMKIHRoZSBJRCBp
biB0aGUgcmVzb3VyY2UgbmFtZS4KCgwKBQQAAgIFEgM+AggKDAoFBAACAgESAz4JFgoMCgUE
AAICAxIDPhkaCgwKBQQAAgIIEgM+G0YKDwoIBAACAgicCAASAz4cRWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet::AutonomousDatabaseCharacterSet ===
    # Fields for AutonomousDatabaseCharacterSet
    # Field: name Type: 9 ()
    # Field: character_set_type Type: 14 (.google.cloud.oracledatabase.v1.AutonomousDatabaseCharacterSet.CharacterSetType)
    # Field: character_set Type: 9 ()

# Enum: AutonomousDatabaseCharacterSet::CharacterSetType
our $AutonomousDatabaseCharacterSet_CHARACTER_SET_TYPE_UNSPECIFIED = 0;
our $AutonomousDatabaseCharacterSet_DATABASE = 1;
our $AutonomousDatabaseCharacterSet_NATIONAL = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/autonomous_database_character_set.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet;

    my $msg = Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet::AutonomousDatabaseCharacterSet->new({
        name => $name,
        character_set_type => $character_set_type,
        character_set => $character_set,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet::AutonomousDatabaseCharacterSet->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/autonomous_database_character_set.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet::AutonomousDatabaseCharacterSet

Details of the Autonomous Database character set resource.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/AutonomousDatabaseCharacterSets/

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the Autonomous Database Character Set resource in
the following format:
projects/{project}/locations/{region}/autonomousDatabaseCharacterSets/{autonomous_database_character_set}

=item * C<< $msg->character_set_type() >> / C<< $msg->character_set_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet::CharacterSetType>)

Output only. The character set type for the Autonomous Database.

=item * C<< $msg->character_set() >> / C<< $msg->character_set($value) >>

Type: C<String>

Output only. The character set name for the Autonomous Database which is
the ID in the resource name.

=back

=head3 Enum: AutonomousDatabaseCharacterSet::CharacterSetType

=over 4

=item * C<CHARACTER_SET_TYPE_UNSPECIFIED> => C<0>

=item * C<DATABASE> => C<1>

=item * C<NATIONAL> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
