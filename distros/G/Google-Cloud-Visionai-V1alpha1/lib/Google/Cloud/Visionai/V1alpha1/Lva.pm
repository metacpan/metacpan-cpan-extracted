package Google::Cloud::Visionai::V1alpha1::Lva;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvdmlzaW9uYWkvdjFhbHBoYTEvbHZhLnByb3RvEh5nb29nbGUuY2xv
dWQudmlzaW9uYWkudjFhbHBoYTEiWQoOQXR0cmlidXRlVmFsdWUSDgoBaRgBIAEoA0gAUgFp
Eg4KAWYYAiABKAJIAFIBZhIOCgFiGAMgASgISABSAWISDgoBcxgEIAEoDEgAUgFzQgcKBXZh
bHVlItkFChJBbmFseXplckRlZmluaXRpb24SGgoIYW5hbHl6ZXIYASABKAlSCGFuYWx5emVy
EhoKCG9wZXJhdG9yGAIgASgJUghvcGVyYXRvchJWCgZpbnB1dHMYAyADKAsyPi5nb29nbGUu
Y2xvdWQudmlzaW9uYWkudjFhbHBoYTEuQW5hbHl6ZXJEZWZpbml0aW9uLlN0cmVhbUlucHV0
UgZpbnB1dHMSUwoFYXR0cnMYBCADKAsyPS5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBo
YTEuQW5hbHl6ZXJEZWZpbml0aW9uLkF0dHJzRW50cnlSBWF0dHJzEmQKDWRlYnVnX29wdGlv
bnMYBSABKAsyPy5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuQW5hbHl6ZXJEZWZp
bml0aW9uLkRlYnVnT3B0aW9uc1IMZGVidWdPcHRpb25zGiMKC1N0cmVhbUlucHV0EhQKBWlu
cHV0GAEgASgJUgVpbnB1dBroAQoMRGVidWdPcHRpb25zEo4BChVlbnZpcm9ubWVudF92YXJp
YWJsZXMYASADKAsyWS5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuQW5hbHl6ZXJE
ZWZpbml0aW9uLkRlYnVnT3B0aW9ucy5FbnZpcm9ubWVudFZhcmlhYmxlc0VudHJ5UhRlbnZp
cm9ubWVudFZhcmlhYmxlcxpHChlFbnZpcm9ubWVudFZhcmlhYmxlc0VudHJ5EhAKA2tleRgB
IAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEaaAoKQXR0cnNFbnRyeRIQCgNr
ZXkYASABKAlSA2tleRJECgV2YWx1ZRgCIAEoCzIuLmdvb2dsZS5jbG91ZC52aXNpb25haS52
MWFscGhhMS5BdHRyaWJ1dGVWYWx1ZVIFdmFsdWU6AjgBImYKEkFuYWx5c2lzRGVmaW5pdGlv
bhJQCglhbmFseXplcnMYASADKAsyMi5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEu
QW5hbHl6ZXJEZWZpbml0aW9uUglhbmFseXplcnNC1gEKImNvbS5nb29nbGUuY2xvdWQudmlz
aW9uYWkudjFhbHBoYTFCCEx2YVByb3RvUAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vdmlzaW9u
YWkvYXBpdjFhbHBoYTEvdmlzaW9uYWlwYjt2aXNpb25haXBiqgIeR29vZ2xlLkNsb3VkLlZp
c2lvbkFJLlYxQWxwaGExygIeR29vZ2xlXENsb3VkXFZpc2lvbkFJXFYxYWxwaGEx6gIhR29v
Z2xlOjpDbG91ZDo6VmlzaW9uQUk6OlYxYWxwaGExSpUcCgYSBA4AcgEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCAoBCBIDEgA7CgkKAgglEgMSADsK
CAoBCBIDEwBVCgkKAggLEgMTAFUKCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQApCgkK
AggIEgMVACkKCAoBCBIDFgA7CgkKAggBEgMWADsKCAoBCBIDFwA7CgkKAggpEgMXADsKCAoB
CBIDGAA6CgkKAggtEgMYADoKQgoCBAASBBsAKgEaNiBSZXByZXNlbnRzIGFuIGFjdHVhbCB2
YWx1ZSBvZiBhbiBvcGVyYXRvciBhdHRyaWJ1dGUuCgoKCgMEAAESAxsIFgogCgQEAAgAEgQd
AikDGhIgQXR0cmlidXRlIHZhbHVlLgoKDAoFBAAIAAESAx0IDQoTCgQEAAIAEgMfBBAaBiBp
bnQuCgoMCgUEAAIABRIDHwQJCgwKBQQAAgABEgMfCgsKDAoFBAACAAMSAx8ODwoVCgQEAAIB
EgMiBBAaCCBmbG9hdC4KCgwKBQQAAgEFEgMiBAkKDAoFBAACAQESAyIKCwoMCgUEAAIBAxID
Ig4PChQKBAQAAgISAyUEDxoHIGJvb2wuCgoMCgUEAAICBRIDJQQICgwKBQQAAgIBEgMlCQoK
DAoFBAACAgMSAyUNDgoWCgQEAAIDEgMoBBAaCSBzdHJpbmcuCgoMCgUEAAIDBRIDKAQJCgwK
BQQAAgMBEgMoCgsKDAoFBAACAwMSAygODwriAQoCBAESBDEAZQEa1QEgRGVmaW5lcyBhbiBB
bmFseXplci4KCiBBbiBhbmFseXplciBwcm9jZXNzZXMgZGF0YSBmcm9tIGl0cyBpbnB1dCBz
dHJlYW1zIHVzaW5nIHRoZSBsb2dpYyBkZWZpbmVkIGluCiB0aGUgT3BlcmF0b3IgdGhhdCBp
dCByZXByZXNlbnRzLiBPZiBjb3Vyc2UsIGl0IHByb2R1Y2VzIGRhdGEgZm9yIHRoZSBvdXRw
dXQKIHN0cmVhbXMgZGVjbGFyZWQgaW4gdGhlIE9wZXJhdG9yLgoKCgoDBAEBEgMxCBoK7QUK
BAQBAwASBEQCRwMa3gUgVGhlIGlucHV0cyB0byB0aGlzIGFuYWx5emVyLgoKIFdlIGFjY2Vw
dCBpbnB1dCBuYW1lIHJlZmVyZW5jZXMgb2YgdGhlIGZvbGxvd2luZyBmb3JtOgogPGFuYWx5
emVyLW5hbWU+OjxvdXRwdXQtYXJndW1lbnQtbmFtZT4KCiBFeGFtcGxlOgoKIFN1cHBvc2Ug
eW91IGhhZCBhbiBvcGVyYXRvciBuYW1lZCAiU29tZU9wIiB0aGF0IGhhcyAyIG91dHB1dAog
YXJndW1lbnRzLCB0aGUgZmlyc3Qgb2Ygd2hpY2ggaXMgbmFtZWQgImZvbyIgYW5kIHRoZSBz
ZWNvbmQgb2Ygd2hpY2ggaXMKIG5hbWVkICJiYXIiLCBhbmQgYW4gb3BlcmF0b3IgbmFtZWQg
Ik15T3AiIHRoYXQgYWNjZXB0cyAyIGlucHV0cy4KCiBBbHNvIHN1cHBvc2UgdGhhdCB0aGVy
ZSBpcyBhbiBhbmFseXplciBuYW1lZCAic29tZS1hbmFseXplciIgdGhhdCBpcwogcnVubmlu
ZyAiU29tZU9wIiBhbmQgYW5vdGhlciBhbmFseXplciBuYW1lZCAibXktYW5hbHl6ZXIiIHJ1
bm5pbmcgIk15T3AiLgoKIFRvIGluZGljYXRlIHRoYXQgIm15LWFuYWx5emVyIiBpcyB0byBj
b25zdW1lICJzb21lLWFuYWx5emVyIidzICJmb28iCiBvdXRwdXQgYXMgaXRzIGZpcnN0IGlu
cHV0IGFuZCAic29tZS1hbmFseXplciIncyAiYmFyIiBvdXRwdXQgYXMgaXRzCiBzZWNvbmQg
aW5wdXQsIHlvdSBjYW4gc2V0IHRoaXMgZmllbGQgdG8gdGhlIGZvbGxvd2luZzoKIGlucHV0
ID0gWyJzb21lLWFuYWx5emVyOmZvbyIsICJzb21lLWFuYWx5emVyOmJhciJdCgoMCgUEAQMA
ARIDRAoVCkMKBgQBAwACABIDRgQVGjQgVGhlIG5hbWUgb2YgdGhlIHN0cmVhbSBpbnB1dCAo
YXMgZGlzY3Vzc2VkIGFib3ZlKS4KCg4KBwQBAwACAAUSA0YECgoOCgcEAQMAAgABEgNGCxAK
DgoHBAEDAAIAAxIDRhMUCj4KBAQBAwESBEoCTQMaMCBPcHRpb25zIGF2YWlsYWJsZSBmb3Ig
ZGVidWdnaW5nIHB1cnBvc2VzIG9ubHkuCgoMCgUEAQMBARIDSgoWCicKBgQBAwECABIDTAQy
GhggRW52aXJvbm1lbnQgdmFyaWFibGVzLgoKDgoHBAEDAQIABhIDTAQXCg4KBwQBAwECAAES
A0wYLQoOCgcEAQMBAgADEgNMMDEKVAoEBAECABIDUgIWGkcgVGhlIG5hbWUgb2YgdGhpcyBh
bmFseXplci4KCiBUZW50YXRpdmVseSBbYS16XVthLXowLTldKihfW2EtejAtOV0rKSouCgoM
CgUEAQIABRIDUgIICgwKBQQBAgABEgNSCREKDAoFBAECAAMSA1IUFQpvCgQEAQIBEgNXAhYa
YiBUaGUgbmFtZSBvZiB0aGUgb3BlcmF0b3IgdGhhdCB0aGlzIGFuYWx5emVyIHJ1bnMuCgog
TXVzdCBtYXRjaCB0aGUgbmFtZSBvZiBhIHN1cHBvcnRlZCBvcGVyYXRvci4KCgwKBQQBAgEF
EgNXAggKDAoFBAECAQESA1cJEQoMCgUEAQIBAxIDVxQVCh0KBAQBAgISA1oCIhoQIElucHV0
IHN0cmVhbXMuCgoMCgUEAQICBBIDWgIKCgwKBQQBAgIGEgNaCxYKDAoFBAECAgESA1oXHQoM
CgUEAQICAxIDWiAhCvsBCgQEAQIDEgNhAiga7QEgVGhlIGF0dHJpYnV0ZSB2YWx1ZXMgdGhh
dCB0aGlzIGFuYWx5emVyIGFwcGxpZXMgdG8gdGhlIG9wZXJhdG9yLgoKIFN1cHBseSBhIG1h
cHBpbmcgYmV0d2VlbiB0aGUgYXR0cmlidXRlIG5hbWVzIGFuZCB0aGUgYWN0dWFsIHZhbHVl
IHlvdSB3aXNoCiB0byBhcHBseS4gSWYgYW4gYXR0cmlidXRlIG5hbWUgaXMgb21pdHRlZCwg
dGhlbiBpdCB3aWxsIHRha2UgYQogcHJlY29uZmlndXJlZCBkZWZhdWx0IHZhbHVlLgoKDAoF
BAECAwYSA2ECHQoMCgUEAQIDARIDYR4jCgwKBQQBAgMDEgNhJicKHQoEBAECBBIDZAIhGhAg
RGVidWcgb3B0aW9ucy4KCgwKBQQBAgQGEgNkAg4KDAoFBAECBAESA2QPHAoMCgUEAQIEAxID
ZB8gCtQCCgIEAhIEbwByARrHAiBEZWZpbmVzIGEgZnVsbCBhbmFseXNpcy4KCiBUaGlzIGlz
IGEgZGVzY3JpcHRpb24gb2YgdGhlIG92ZXJhbGwgbGl2ZSBhbmFseXRpY3MgcGlwZWxpbmUu
CiBZb3UgbWF5IHRoaW5rIG9mIHRoaXMgYXMgYW4gZWRnZSBsaXN0IHJlcHJlc2VudGF0aW9u
IG9mIGEgbXVsdGlncmFwaC4KCiBUaGlzIG1heSBiZSBkaXJlY3RseSBhdXRob3JlZCBieSBh
IGh1bWFuIGluIHByb3RvYnVmIHRleHRmb3JtYXQsIG9yIGl0IG1heSBiZQogZ2VuZXJhdGVk
IGJ5IGEgcHJvZ3JhbW1pbmcgQVBJIChwZXJoYXBzIFB5dGhvbiBvciBKYXZhU2NyaXB0IGRl
cGVuZGluZyBvbgogY29udGV4dCkuCgoKCgMEAgESA28IGgokCgQEAgIAEgNxAiwaFyBBbmFs
eXplciBkZWZpbml0aW9ucy4KCgwKBQQCAgAEEgNxAgoKDAoFBAICAAYSA3ELHQoMCgUEAgIA
ARIDcR4nCgwKBQQCAgADEgNxKitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Visionai::V1alpha1::Lva::AttributeValue ===
    # Fields for AttributeValue
    # Field: i Type: 3 ()
    # Field: f Type: 2 ()
    # Field: b Type: 8 ()
    # Field: s Type: 12 ()

# === Message: Google::Cloud::Visionai::V1alpha1::Lva::AnalyzerDefinition ===
    # Fields for AnalyzerDefinition
    # Field: analyzer Type: 9 ()
    # Field: operator Type: 9 ()
    # Field: inputs Type: 11 (.google.cloud.visionai.v1alpha1.AnalyzerDefinition.StreamInput)
    # Field: attrs Type: 11 (.google.cloud.visionai.v1alpha1.AnalyzerDefinition.AttrsEntry)
    # Field: debug_options Type: 11 (.google.cloud.visionai.v1alpha1.AnalyzerDefinition.DebugOptions)

# === Message: Google::Cloud::Visionai::V1alpha1::Lva::AnalysisDefinition ===
    # Fields for AnalysisDefinition
    # Field: analyzers Type: 11 (.google.cloud.visionai.v1alpha1.AnalyzerDefinition)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Visionai::V1alpha1::Lva - Compiled Protocol Buffers messages for google/cloud/visionai/v1alpha1/lva.proto

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1alpha1::Lva;

    my $msg = Google::Cloud::Visionai::V1alpha1::Lva::AttributeValue->new({
        i => $i,
        f => $f,
        b => $b,
        s => $s,
    });

    # Read or update a field
    my $val = $msg->i();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Visionai::V1alpha1::Lva::AttributeValue->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/visionai/v1alpha1/lva.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Visionai::V1alpha1::Lva::AttributeValue

Represents an actual value of an operator attribute.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->i() >> / C<< $msg->i($value) >>

Type: C<Int64>

int.

=item * C<< $msg->f() >> / C<< $msg->f($value) >>

Type: C<Float>

float.

=item * C<< $msg->b() >> / C<< $msg->b($value) >>

Type: C<Bool>

bool.

=item * C<< $msg->s() >> / C<< $msg->s($value) >>

Type: C<Bytes>

string.

=back

=head2 Google::Cloud::Visionai::V1alpha1::Lva::AnalyzerDefinition

Defines an Analyzer.

An analyzer processes data from its input streams using the logic defined in
the Operator that it represents. Of course, it produces data for the output
streams declared in the Operator.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->analyzer() >> / C<< $msg->analyzer($value) >>

Type: C<String>

The name of this analyzer.

Tentatively [a-z][a-z0-9]*(_[a-z0-9]+)*.

=item * C<< $msg->operator() >> / C<< $msg->operator($value) >>

Type: C<String>

The name of the operator that this analyzer runs.

Must match the name of a supported operator.

=item * C<< $msg->inputs() >> / C<< $msg->inputs($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::Lva::AnalyzerDefinition::StreamInput>)

Input streams.

=item * C<< $msg->attrs() >> / C<< $msg->attrs($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::Lva::AnalyzerDefinition::AttrsEntry>)

The attribute values that this analyzer applies to the operator.

Supply a mapping between the attribute names and the actual value you wish
to apply. If an attribute name is omitted, then it will take a
preconfigured default value.

=item * C<< $msg->debug_options() >> / C<< $msg->debug_options($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::Lva::AnalyzerDefinition::DebugOptions>)

Debug options.

=back

=head2 Google::Cloud::Visionai::V1alpha1::Lva::AnalysisDefinition

Defines a full analysis.

This is a description of the overall live analytics pipeline.
You may think of this as an edge list representation of a multigraph.

This may be directly authored by a human in protobuf textformat, or it may be
generated by a programming API (perhaps Python or JavaScript depending on
context).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->analyzers() >> / C<< $msg->analyzers($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::Lva::AnalyzerDefinition>)

Analyzer definitions.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Visionai::V1alpha1::Lva::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
