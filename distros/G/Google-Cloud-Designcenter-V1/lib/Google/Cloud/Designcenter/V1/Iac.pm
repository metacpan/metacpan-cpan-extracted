package Google::Cloud::Designcenter::V1::Iac;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Designcenter::V1::Parameters };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL2lhYy5wcm90bxIcZ29vZ2xlLmNsb3Vk
LmRlc2lnbmNlbnRlci52MRotZ29vZ2xlL2Nsb3VkL2Rlc2lnbmNlbnRlci92MS9wYXJhbWV0
ZXJzLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvImIKE1Jvb3RNb2R1bGVz
TWV0YWRhdGESSwoMcm9vdF9tb2R1bGVzGAEgAygLMiguZ29vZ2xlLmNsb3VkLmRlc2lnbmNl
bnRlci52MS5Sb290TW9kdWxlUgtyb290TW9kdWxlcyLLAgoKUm9vdE1vZHVsZRIOCgJpZBgB
IAEoCVICaWQSHgoKY29tcG9uZW50cxgCIAMoCVIKY29tcG9uZW50cxJWCgxkZXBlbmRlbmNp
ZXMYAyADKAsyMi5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLlJvb3RNb2R1bGVEZXBl
bmRlbmN5UgxkZXBlbmRlbmNpZXMSWAoPaW5wdXRfdmFyaWFibGVzGAQgAygLMi8uZ29vZ2xl
LmNsb3VkLmRlc2lnbmNlbnRlci52MS5Sb290SW5wdXRWYXJpYWJsZVIOaW5wdXRWYXJpYWJs
ZXMSWwoQb3V0cHV0X3ZhcmlhYmxlcxgFIAMoCzIwLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50
ZXIudjEuUm9vdE91dHB1dFZhcmlhYmxlUg9vdXRwdXRWYXJpYWJsZXMihQEKFFJvb3RNb2R1
bGVEZXBlbmRlbmN5EiQKDnJvb3RfbW9kdWxlX2lkGAEgASgJUgxyb290TW9kdWxlSWQSRwoK
cGFyYW1ldGVycxgCIAMoCzInLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuUGFyYW1l
dGVyUgpwYXJhbWV0ZXJzItUBChFSb290SW5wdXRWYXJpYWJsZRIaCgh2YXJpYWJsZRgBIAEo
CVIIdmFyaWFibGUSIwoNdmFyaWFibGVfdHlwZRgCIAEoCVIMdmFyaWFibGVUeXBlEiwKBXZh
bHVlGAMgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlUgV2YWx1ZRI7Cg1kZWZhdWx0X3Zh
bHVlGAQgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlUgxkZWZhdWx0VmFsdWUSFAoFYWxp
YXMYBSABKAlSBWFsaWFzIjAKElJvb3RPdXRwdXRWYXJpYWJsZRIaCgh2YXJpYWJsZRgBIAEo
CVIIdmFyaWFibGUibAoPVGVycmFmb3JtTW9kdWxlEhYKBnNvdXJjZRgBIAEoCVIGc291cmNl
EkEKBWZpbGVzGAIgAygLMisuZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5UZXJyYWZv
cm1GaWxlUgVmaWxlcyI9Cg1UZXJyYWZvcm1GaWxlEhIKBHBhdGgYASABKAlSBHBhdGgSGAoH
Y29udGVudBgCIAEoCVIHY29udGVudELUAQogY29tLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50
ZXIudjFCCElhY1Byb3RvUAFaRGNsb3VkLmdvb2dsZS5jb20vZ28vZGVzaWduY2VudGVyL2Fw
aXYxL2Rlc2lnbmNlbnRlcnBiO2Rlc2lnbmNlbnRlcnBiqgIcR29vZ2xlLkNsb3VkLkRlc2ln
bkNlbnRlci5WMcoCHEdvb2dsZVxDbG91ZFxEZXNpZ25DZW50ZXJcVjHqAh9Hb29nbGU6OkNs
b3VkOjpEZXNpZ25DZW50ZXI6OlYxSuMbCgYSBA4AdgEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQACUKCQoCAwASAxIANwoJCgIDARIDEwAmCggKAQgSAxUA
OQoJCgIIJRIDFQA5CggKAQgSAxYAWwoJCgIICxIDFgBbCggKAQgSAxcAIgoJCgIIChIDFwAi
CggKAQgSAxgAKQoJCgIICBIDGAApCggKAQgSAxkAOQoJCgIIARIDGQA5CggKAQgSAxoAOQoJ
CgIIKRIDGgA5CggKAQgSAxsAOAoJCgIILRIDGwA4CiQKAgQAEgQeACEBGhggUm9vdCBtb2R1
bGVzIG1ldGFkYXRhLgoKCgoDBAABEgMeCBsKLgoEBAACABIDIAInGiEgTGlzdCBvZiB0ZXJy
YWZvcm0gcm9vdCBtb2R1bGVzLgoKDAoFBAACAAQSAyACCgoMCgUEAAIABhIDIAsVCgwKBQQA
AgABEgMgFiIKDAoFBAACAAMSAyAlJgopCgIEARIEJAA5ARodIE1ldGFkYXRhIGZvciBhIHJv
b3QgbW9kdWxlLgoKCgoDBAEBEgMkCBIKrwEKBAQBAgASAygCEBqhASBJZGVudGlmaWVyIG9m
IHRoZSByb290IG1vZHVsZS4gVGhpcyBpcyB0aGUgZGlyZWN0b3J5IG5hbWUgb2YgdGhlIHJv
b3QKIG1vZHVsZSBpbiB0aGUgZ2VuZXJhdGVkIHRlcnJhZm9ybSB3aGljaCBpcyBhbHNvIHNh
bWUgYXMgdGhlIGNvcnJlc3BvbmRpbmcKIGNvbXBvbmVudCBJRC4KCgwKBQQBAgAFEgMoAggK
DAoFBAECAAESAygJCwoMCgUEAQIAAxIDKA4PCpMCCgQEAQIBEgMuAiEahQIgTGlzdCBvZiBB
cHBsaWNhdGlvbiBEZXNpZ24gQ2VudGVyIGNvbXBvbmVudCBuYW1lcyBhc3NvY2lhdGVkIHdp
dGggdGhpcyByb290CiBtb2R1bGUuIEZvciBzdGFuZGFyZCBhcHAgdGVtcGxhdGUgdHlwZSBj
b21wb25lbnRzLCB0aGlzIGxpc3Qgd2lsbCBoYXZlIGEKIHNpbmdsZSBlbGVtZW50LiBGb3Ig
c2VydmljZSAvIHdvcmtsb2FkIC8gYXNzZXQgY29tcG9uZW50cywgdGhpcyBsaXN0IHdpbGwK
IGNvbnRhaW4gYWxsIHN1Y2ggY29tcG9uZW50IG5hbWVzLgoKDAoFBAECAQQSAy4CCgoMCgUE
AQIBBRIDLgsRCgwKBQQBAgEBEgMuEhwKDAoFBAECAQMSAy4fIApnCgQEAQICEgMyAjEaWiBE
ZXBlbmRlbmNpZXMgb2YgdGhpcyByb290IG1vZHVsZS4gVGhlIGRlcGVuZGVuY3kgZ3JhcGgg
b2Ygcm9vdCBtb2R1bGVzCiBtdXN0IGJlIGFjeWNsaWMuCgoMCgUEAQICBBIDMgIKCgwKBQQB
AgIGEgMyCx8KDAoFBAECAgESAzIgLAoMCgUEAQICAxIDMi8wCjsKBAQBAgMSAzUCMRouIExp
c3Qgb2YgaW5wdXQgdmFyaWFibGVzIG9mIHRoaXMgcm9vdCBtb2R1bGUuCgoMCgUEAQIDBBID
NQIKCgwKBQQBAgMGEgM1CxwKDAoFBAECAwESAzUdLAoMCgUEAQIDAxIDNS8wCjwKBAQBAgQS
AzgCMxovIExpc3Qgb2Ygb3V0cHV0IHZhcmlhYmxlcyBvZiB0aGlzIHJvb3QgbW9kdWxlLgoK
DAoFBAECBAQSAzgCCgoMCgUEAQIEBhIDOAsdCgwKBQQBAgQBEgM4Hi4KDAoFBAECBAMSAzgx
MgolCgIEAhIEPABCARoZIFJvb3QgbW9kdWxlIGRlcGVuZGVuY3kuCgoKCgMEAgESAzwIHAot
CgQEAgIAEgM+AhwaICBJZGVudGlmaWVyIG9mIHRoZSByb290IG1vZHVsZS4KCgwKBQQCAgAF
EgM+AggKDAoFBAICAAESAz4JFwoMCgUEAgIAAxIDPhobCjoKBAQCAgESA0ECJBotIFBhcmFt
ZXRlcnMgYXNzb2NpYXRlZCB3aXRoIHRoaXMgZGVwZW5kZW5jeS4KCgwKBQQCAgEEEgNBAgoK
DAoFBAICAQYSA0ELFAoMCgUEAgIBARIDQRUfCgwKBQQCAgEDEgNBIiMKLgoCBAMSBEUAVAEa
IiBJbnB1dCB2YXJpYWJsZSBvZiBhIHJvb3QgbW9kdWxlLgoKCgoDBAMBEgNFCBkKKgoEBAMC
ABIDRwIWGh0gTmFtZSBvZiB0aGUgaW5wdXQgdmFyaWFibGUuCgoMCgUEAwIABRIDRwIICgwK
BQQDAgABEgNHCREKDAoFBAMCAAMSA0cUFQoqCgQEAwIBEgNKAhsaHSBUeXBlIG9mIHRoZSBp
bnB1dCB2YXJpYWJsZS4KCgwKBQQDAgEFEgNKAggKDAoFBAMCAQESA0oJFgoMCgUEAwIBAxID
ShkaCiwKBAQDAgISA00CIhofIFZhbHVlIGZvciB0aGUgaW5wdXQgdmFyaWFibGUuCgoMCgUE
AwICBhIDTQIXCgwKBQQDAgIBEgNNGB0KDAoFBAMCAgMSA00gIQozCgQEAwIDEgNQAioaJiBE
ZWZhdWx0IHZhbHVlIG9mIHRoZSBpbnB1dCB2YXJpYWJsZS4KCgwKBQQDAgMGEgNQAhcKDAoF
BAMCAwESA1AYJQoMCgUEAwIDAxIDUCgpCisKBAQDAgQSA1MCExoeIEFsaWFzIGZvciB0aGUg
dmFyaWFibGUgbmFtZS4KCgwKBQQDAgQFEgNTAggKDAoFBAMCBAESA1MJDgoMCgUEAwIEAxID
UxESCi8KAgQEEgRXAFoBGiMgT3V0cHV0IHZhcmlhYmxlIG9mIGEgcm9vdCBtb2R1bGUuCgoK
CgMEBAESA1cIGgorCgQEBAIAEgNZAhYaHiBOYW1lIG9mIHRoZSBvdXRwdXQgdmFyaWFibGUu
CgoMCgUEBAIABRIDWQIICgwKBQQEAgABEgNZCREKDAoFBAQCAAMSA1kUFQqGAgoCBAUSBGcA
bQEa+QEgUmVwcmVzZW50cyBhIFRlcnJhZm9ybSBtb2R1bGUsIHdoaWNoIGlzIGEgY29sbGVj
dGlvbiBvZiBUZXJyYWZvcm0gZmlsZXMuCiBFZzoKIHsKICAgInNvdXJjZSI6ICJnaXQ6Omh0
dHBzOi8vZ2l0aHViLmNvbS9teS1vcmcvbXktcmVwbyIsCiAgICJmaWxlcyI6IFsKICAgICB7
CiAgICAgICAicGF0aCI6ICIvcGF0aC90by9maWxlL21haW4udGYiLAogICAgICAgImNvbnRl
bnQiOiAidGYgZmlsZSBjb250ZW50IgogICAgIH0KICAgXQogfQoKCgoDBAUBEgNnCBcKMgoE
BAUCABIDaQIUGiUgVGhlIHNvdXJjZSBvZiB0aGUgVGVycmFmb3JtIG1vZHVsZS4KCgwKBQQF
AgAFEgNpAggKDAoFBAUCAAESA2kJDwoMCgUEBQIAAxIDaRITCjUKBAQFAgESA2wCIxooIFRo
ZSBmaWxlcyB3aXRoaW4gdGhlIFRlcnJhZm9ybSBtb2R1bGUuCgoMCgUEBQIBBBIDbAIKCgwK
BQQFAgEGEgNsCxgKDAoFBAUCAQESA2wZHgoMCgUEBQIBAxIDbCEiCjEKAgQGEgRwAHYBGiUg
UmVwcmVzZW50cyBhIHNpbmdsZSBUZXJyYWZvcm0gZmlsZS4KCgoKAwQGARIDcAgVCi4KBAQG
AgASA3ICEhohIFRoZSBwYXRoIG9mIHRoZSBUZXJyYWZvcm0gZmlsZS4KCgwKBQQGAgAFEgNy
AggKDAoFBAYCAAESA3IJDQoMCgUEBgIAAxIDchARCjEKBAQGAgESA3UCFRokIFRoZSBjb250
ZW50IG9mIHRoZSBUZXJyYWZvcm0gZmlsZS4KCgwKBQQGAgEFEgN1AggKDAoFBAYCAQESA3UJ
EAoMCgUEBgIBAxIDdRMUYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Designcenter::V1::Iac::RootModulesMetadata ===
    # Fields for RootModulesMetadata
    # Field: root_modules Type: 11 (.google.cloud.designcenter.v1.RootModule)

# === Message: Google::Cloud::Designcenter::V1::Iac::RootModule ===
    # Fields for RootModule
    # Field: id Type: 9 ()
    # Field: components Type: 9 ()
    # Field: dependencies Type: 11 (.google.cloud.designcenter.v1.RootModuleDependency)
    # Field: input_variables Type: 11 (.google.cloud.designcenter.v1.RootInputVariable)
    # Field: output_variables Type: 11 (.google.cloud.designcenter.v1.RootOutputVariable)

# === Message: Google::Cloud::Designcenter::V1::Iac::RootModuleDependency ===
    # Fields for RootModuleDependency
    # Field: root_module_id Type: 9 ()
    # Field: parameters Type: 11 (.google.cloud.designcenter.v1.Parameter)

# === Message: Google::Cloud::Designcenter::V1::Iac::RootInputVariable ===
    # Fields for RootInputVariable
    # Field: variable Type: 9 ()
    # Field: variable_type Type: 9 ()
    # Field: value Type: 11 (.google.protobuf.Value)
    # Field: default_value Type: 11 (.google.protobuf.Value)
    # Field: alias Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::Iac::RootOutputVariable ===
    # Fields for RootOutputVariable
    # Field: variable Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::Iac::TerraformModule ===
    # Fields for TerraformModule
    # Field: source Type: 9 ()
    # Field: files Type: 11 (.google.cloud.designcenter.v1.TerraformFile)

# === Message: Google::Cloud::Designcenter::V1::Iac::TerraformFile ===
    # Fields for TerraformFile
    # Field: path Type: 9 ()
    # Field: content Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Designcenter::V1::Iac - Compiled Protocol Buffers messages for google/cloud/designcenter/v1/iac.proto

=head1 SYNOPSIS

    use Google::Cloud::Designcenter::V1::Iac;

    my $msg = Google::Cloud::Designcenter::V1::Iac::RootModulesMetadata->new({
        root_modules => $root_modules,
    });

    # Read or update a field
    my $val = $msg->root_modules();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Designcenter::V1::Iac::RootModulesMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/designcenter/v1/iac.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Designcenter::V1::Iac::RootModulesMetadata

Root modules metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->root_modules() >> / C<< $msg->root_modules($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Iac::RootModule>)

List of terraform root modules.

=back

=head2 Google::Cloud::Designcenter::V1::Iac::RootModule

Metadata for a root module.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Identifier of the root module. This is the directory name of the root
module in the generated terraform which is also same as the corresponding
component ID.

=item * C<< $msg->components() >> / C<< $msg->components($value) >>

Type: C<String>

List of Application Design Center component names associated with this root
module. For standard app template type components, this list will have a
single element. For service / workload / asset components, this list will
contain all such component names.

=item * C<< $msg->dependencies() >> / C<< $msg->dependencies($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Iac::RootModuleDependency>)

Dependencies of this root module. The dependency graph of root modules
must be acyclic.

=item * C<< $msg->input_variables() >> / C<< $msg->input_variables($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Iac::RootInputVariable>)

List of input variables of this root module.

=item * C<< $msg->output_variables() >> / C<< $msg->output_variables($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Iac::RootOutputVariable>)

List of output variables of this root module.

=back

=head2 Google::Cloud::Designcenter::V1::Iac::RootModuleDependency

Root module dependency.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->root_module_id() >> / C<< $msg->root_module_id($value) >>

Type: C<String>

Identifier of the root module.

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Parameters::Parameter>)

Parameters associated with this dependency.

=back

=head2 Google::Cloud::Designcenter::V1::Iac::RootInputVariable

Input variable of a root module.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->variable() >> / C<< $msg->variable($value) >>

Type: C<String>

Name of the input variable.

=item * C<< $msg->variable_type() >> / C<< $msg->variable_type($value) >>

Type: C<String>

Type of the input variable.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Value for the input variable.

=item * C<< $msg->default_value() >> / C<< $msg->default_value($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Default value of the input variable.

=item * C<< $msg->alias() >> / C<< $msg->alias($value) >>

Type: C<String>

Alias for the variable name.

=back

=head2 Google::Cloud::Designcenter::V1::Iac::RootOutputVariable

Output variable of a root module.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->variable() >> / C<< $msg->variable($value) >>

Type: C<String>

Name of the output variable.

=back

=head2 Google::Cloud::Designcenter::V1::Iac::TerraformModule

Represents a Terraform module, which is a collection of Terraform files.
Eg:
{
  "source": "git::https://github.com/my-org/my-repo",
  "files": [
    {
      "path": "/path/to/file/main.tf",
      "content": "tf file content"
    }
  ]
}

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<String>

The source of the Terraform module.

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Iac::TerraformFile>)

The files within the Terraform module.

=back

=head2 Google::Cloud::Designcenter::V1::Iac::TerraformFile

Represents a single Terraform file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

The path of the Terraform file.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

The content of the Terraform file.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Designcenter::V1::Iac::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
