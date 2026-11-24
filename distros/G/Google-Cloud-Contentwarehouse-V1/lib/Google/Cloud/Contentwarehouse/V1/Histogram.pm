package Google::Cloud::Contentwarehouse::V1::Histogram;

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
CjBnb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9oaXN0b2dyYW0ucHJvdG8SIGdv
b2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvItsBCg5IaXN0b2dyYW1RdWVy
eRInCg9oaXN0b2dyYW1fcXVlcnkYASABKAlSDmhpc3RvZ3JhbVF1ZXJ5Ej0KG3JlcXVpcmVf
cHJlY2lzZV9yZXN1bHRfc2l6ZRgCIAEoCFIYcmVxdWlyZVByZWNpc2VSZXN1bHRTaXplEmEK
B2ZpbHRlcnMYAyABKAsyQi5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5IaXN0
b2dyYW1RdWVyeVByb3BlcnR5TmFtZUZpbHRlckID4EEBUgdmaWx0ZXJzIuECCiBIaXN0b2dy
YW1RdWVyeVByb3BlcnR5TmFtZUZpbHRlchJeChBkb2N1bWVudF9zY2hlbWFzGAEgAygJQjP6
QTAKLmNvbnRlbnR3YXJlaG91c2UuZ29vZ2xlYXBpcy5jb20vRG9jdW1lbnRTY2hlbWFSD2Rv
Y3VtZW50U2NoZW1hcxIlCg5wcm9wZXJ0eV9uYW1lcxgCIAMoCVINcHJvcGVydHlOYW1lcxJo
CgZ5X2F4aXMYAyABKA4yUS5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5IaXN0
b2dyYW1RdWVyeVByb3BlcnR5TmFtZUZpbHRlci5IaXN0b2dyYW1ZQXhpc1IFeUF4aXMiTAoO
SGlzdG9ncmFtWUF4aXMSHAoYSElTVE9HUkFNX1lBWElTX0RPQ1VNRU5UEAASHAoYSElTVE9H
UkFNX1lBWElTX1BST1BFUlRZEAEi4gEKFEhpc3RvZ3JhbVF1ZXJ5UmVzdWx0EicKD2hpc3Rv
Z3JhbV9xdWVyeRgBIAEoCVIOaGlzdG9ncmFtUXVlcnkSYwoJaGlzdG9ncmFtGAIgAygLMkUu
Z29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuSGlzdG9ncmFtUXVlcnlSZXN1bHQu
SGlzdG9ncmFtRW50cnlSCWhpc3RvZ3JhbRo8Cg5IaXN0b2dyYW1FbnRyeRIQCgNrZXkYASAB
KAlSA2tleRIUCgV2YWx1ZRgCIAEoA1IFdmFsdWU6AjgBQvYBCiRjb20uZ29vZ2xlLmNsb3Vk
LmNvbnRlbnR3YXJlaG91c2UudjFCDkhpc3RvZ3JhbVByb3RvUAFaUGNsb3VkLmdvb2dsZS5j
b20vZ28vY29udGVudHdhcmVob3VzZS9hcGl2MS9jb250ZW50d2FyZWhvdXNlcGI7Y29udGVu
dHdhcmVob3VzZXBiqgIgR29vZ2xlLkNsb3VkLkNvbnRlbnRXYXJlaG91c2UuVjHKAiBHb29n
bGVcQ2xvdWRcQ29udGVudFdhcmVob3VzZVxWMeoCI0dvb2dsZTo6Q2xvdWQ6OkNvbnRlbnRX
YXJlaG91c2U6OlYxSsEdCgYSBA4AbAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQACkKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUAPQoJCgIIJRID
FQA9CggKAQgSAxYAZwoJCgIICxIDFgBnCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgA
LwoJCgIICBIDGAAvCggKAQgSAxkAPQoJCgIIARIDGQA9CggKAQgSAxoAPQoJCgIIKRIDGgA9
CggKAQgSAxsAPAoJCgIILRIDGwA8CiQKAgQAEgQeADMBGhggVGhlIGhpc3RvZ3JhbSByZXF1
ZXN0LgoKCgoDBAABEgMeCBYK/QEKBAQAAgASAyUCHRrvASBBbiBleHByZXNzaW9uIHNwZWNp
ZmllcyBhIGhpc3RvZ3JhbSByZXF1ZXN0IGFnYWluc3QgbWF0Y2hpbmcgZG9jdW1lbnRzIGZv
cgogc2VhcmNoZXMuCgogU2VlCiBbU2VhcmNoRG9jdW1lbnRzUmVxdWVzdC5oaXN0b2dyYW1f
cXVlcmllc11bZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuU2VhcmNoRG9jdW1l
bnRzUmVxdWVzdC5oaXN0b2dyYW1fcXVlcmllc10KIGZvciBkZXRhaWxzIGFib3V0IHN5bnRh
eC4KCgwKBQQAAgAFEgMlAggKDAoFBAACAAESAyUJGAoMCgUEAAIAAxIDJRscCp8BCgQEAAIB
EgMrAicakQEgQ29udHJvbHMgaWYgdGhlIGhpc3RvZ3JhbSBxdWVyeSByZXF1aXJlcyB0aGUg
cmV0dXJuIG9mIGEgcHJlY2lzZSBjb3VudC4KIEVuYWJsZSB0aGlzIGZsYWcgbWF5IGFkdmVy
c2VseSBpbXBhY3QgcGVyZm9ybWFuY2UuCgogRGVmYXVsdHMgdG8gdHJ1ZS4KCgwKBQQAAgEF
EgMrAgYKDAoFBAACAQESAysHIgoMCgUEAAIBAxIDKyUmCrMCCgQEAAICEgQxAjIvGqQCIE9w
dGlvbmFsLiBGaWx0ZXIgdGhlIHJlc3VsdCBvZiBoaXN0b2dyYW0gcXVlcnkgYnkgdGhlIHBy
b3BlcnR5IG5hbWVzLiBJdAogb25seSB3b3JrcyB3aXRoIGhpc3RvZ3JhbSBxdWVyeSBjb3Vu
dCgnRmlsdGVyYWJsZVByb3BlcnRpZXMnKS4gSXQgaXMgYW4KIG9wdGlvbmFsLiBJdCB3aWxs
IHBlcmZvcm0gaGlzdG9ncmFtIG9uIGFsbCB0aGUgcHJvcGVydHkgbmFtZXMgZm9yIGFsbCB0
aGUKIGRvY3VtZW50IHNjaGVtYXMuIFNldHRpbmcgdGhpcyBmaWVsZCB3aWxsIGhhdmUgYSBi
ZXR0ZXIgcGVyZm9ybWFuY2UuCgoMCgUEAAICBhIDMQIiCgwKBQQAAgIBEgMxIyoKDAoFBAAC
AgMSAzEtLgoMCgUEAAICCBIDMgYuCg8KCAQAAgIInAgAEgMyBy0KCgoCBAESBDUAXAEKCgoD
BAEBEgM1CCgKwQEKBAQBBAASBDwCQgMasgEgVGhlIHJlc3VsdCBvZiB0aGUgaGlzdG9ncmFt
IHF1ZXJ5IGNvdW50KCdGaWx0ZXJhYmxlUHJvcGVydGllcycpIHVzaW5nCiBISVNUT0dSQU1f
WUFYSVNfRE9DVU1FTlQgd2lsbCBiZToKIGludm9pY2VfaWQ6IDIKIGFkZHJlc3M6IDEKIHBh
eW1lbnRfbWV0aG9kOiAyCiBsaW5lX2l0ZW1fZGVzY3JpcHRpb246IDEKCgwKBQQBBAABEgM8
BxUKNwoGBAEEAAIAEgM+BCEaKCBDb3VudCB0aGUgZG9jdW1lbnRzIHBlciBwcm9wZXJ0eSBu
YW1lLgoKDgoHBAEEAAIAARIDPgQcCg4KBwQBBAACAAISAz4fIAo4CgYEAQQAAgESA0EEIRop
IENvdW50IHRoZSBwcm9wZXJ0aWVzIHBlciBwcm9wZXJ0eSBuYW1lLgoKDgoHBAEEAAIBARID
QQQcCg4KBwQBBAACAQISA0EfIArBAwoEBAECABIETAJOBRqyAyBUaGlzIGZpbHRlciBzcGVj
aWZpZXMgdGhlIGV4YWN0IGRvY3VtZW50IHNjaGVtYShzKQogW0RvY3VtZW50LmRvY3VtZW50
X3NjaGVtYV9uYW1lXVtnb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5Eb2N1bWVu
dC5kb2N1bWVudF9zY2hlbWFfbmFtZV0KIHRvIHJ1biBoaXN0b2dyYW0gcXVlcnkgYWdhaW5z
dC4gSXQgaXMgb3B0aW9uYWwuIEl0IHdpbGwgcGVyZm9ybSBoaXN0b2dyYW0KIGZvciBwcm9w
ZXJ0eSBuYW1lcyBmb3IgYWxsIHRoZSBkb2N1bWVudCBzY2hlbWFzIGlmIGl0IGlzIG5vdCBz
ZXQuCgogQXQgbW9zdCAxMCBkb2N1bWVudCBzY2hlbWEgbmFtZXMgYXJlIGFsbG93ZWQuCiBG
b3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259
L2RvY3VtZW50U2NoZW1hcy97ZG9jdW1lbnRfc2NoZW1hX2lkfS4KCgwKBQQBAgAEEgNMAgoK
DAoFBAECAAUSA0wLEQoMCgUEAQIAARIDTBIiCgwKBQQBAgADEgNMJSYKDQoFBAECAAgSBEwn
TgQKDwoHBAECAAifCBIETChOAwqmAwoEBAECARIDVwIlGpgDIEl0IGlzIG9wdGlvbmFsLiBJ
dCB3aWxsIHBlcmZvcm0gaGlzdG9ncmFtIGZvciBhbGwgdGhlIHByb3BlcnR5IG5hbWVzIGlm
IGl0CiBpcyBub3Qgc2V0LgogVGhlIHByb3BlcnRpZXMgbmVlZCB0byBiZSBkZWZpbmVkIHdp
dGggdGhlIGlzX2ZpbHRlcmFibGUgZmxhZyBzZXQgdG8KIHRydWUgYW5kIHRoZSBuYW1lIG9m
IHRoZSBwcm9wZXJ0eSBzaG91bGQgYmUgaW4gdGhlIGZvcm1hdDoKICJzY2hlbWFJZC5wcm9w
ZXJ0eU5hbWUiLiBUaGUgcHJvcGVydHkgbmVlZHMgdG8gYmUgZGVmaW5lZCBpbiB0aGUgc2No
ZW1hLgogRXhhbXBsZTogdGhlIHNjaGVtYSBpZCBpcyBhYmMuIFRoZW4gdGhlIG5hbWUgb2Yg
cHJvcGVydHkgZm9yIHByb3BlcnR5CiBNT1JUR0FHRV9UWVBFIHdpbGwgYmUgImFiYy5NT1JU
R0FHRV9UWVBFIi4KCgwKBQQBAgEEEgNXAgoKDAoFBAECAQUSA1cLEQoMCgUEAQIBARIDVxIg
CgwKBQQBAgEDEgNXIyQKXAoEBAECAhIDWwIcGk8gQnkgZGVmYXVsdCwgdGhlIHlfYXhpcyBp
cyBISVNUT0dSQU1fWUFYSVNfRE9DVU1FTlQgaWYgdGhpcyBmaWVsZCBpcyBub3QKIHNldC4K
CgwKBQQBAgIGEgNbAhAKDAoFBAECAgESA1sRFwoMCgUEAQICAxIDWxobCoYBCgIEAhIEYQBs
ARp6IEhpc3RvZ3JhbSByZXN1bHQgdGhhdCBtYXRjaGVzCiBbSGlzdG9ncmFtUXVlcnldW2dv
b2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLkhpc3RvZ3JhbVF1ZXJ5XSBzcGVjaWZp
ZWQKIGluIHNlYXJjaGVzLgoKCgoDBAIBEgNhCBwKLgoEBAICABIDYwIdGiEgUmVxdWVzdGVk
IGhpc3RvZ3JhbSBleHByZXNzaW9uLgoKDAoFBAICAAUSA2MCCAoMCgUEAgIAARIDYwkYCgwK
BQQCAgADEgNjGxwK4gEKBAQCAgESA2sCIxrUASBBIG1hcCBmcm9tIHRoZSB2YWx1ZXMgb2Yg
dGhlIGZhY2V0IGFzc29jaWF0ZWQgd2l0aCBkaXN0aW5jdCB2YWx1ZXMgdG8gdGhlCiBudW1i
ZXIgb2YgbWF0Y2hpbmcgZW50cmllcyB3aXRoIGNvcnJlc3BvbmRpbmcgdmFsdWUuCgogVGhl
IGtleSBmb3JtYXQgaXM6CgogKiAoZm9yIHN0cmluZyBoaXN0b2dyYW0pIHN0cmluZyB2YWx1
ZXMgc3RvcmVkIGluIHRoZSBmaWVsZC4KCgwKBQQCAgEGEgNrAhQKDAoFBAICAQESA2sVHgoM
CgUEAgIBAxIDayEiYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::Histogram::HistogramQuery ===
    # Fields for HistogramQuery
    # Field: histogram_query Type: 9 ()
    # Field: require_precise_result_size Type: 8 ()
    # Field: filters Type: 11 (.google.cloud.contentwarehouse.v1.HistogramQueryPropertyNameFilter)

# === Message: Google::Cloud::Contentwarehouse::V1::Histogram::HistogramQueryPropertyNameFilter ===
    # Fields for HistogramQueryPropertyNameFilter
    # Field: document_schemas Type: 9 ()
    # Field: property_names Type: 9 ()
    # Field: y_axis Type: 14 (.google.cloud.contentwarehouse.v1.HistogramQueryPropertyNameFilter.HistogramYAxis)

# Enum: HistogramQueryPropertyNameFilter::HistogramYAxis
our $HistogramQueryPropertyNameFilter_HISTOGRAM_YAXIS_DOCUMENT = 0;
our $HistogramQueryPropertyNameFilter_HISTOGRAM_YAXIS_PROPERTY = 1;

# === Message: Google::Cloud::Contentwarehouse::V1::Histogram::HistogramQueryResult ===
    # Fields for HistogramQueryResult
    # Field: histogram_query Type: 9 ()
    # Field: histogram Type: 11 (.google.cloud.contentwarehouse.v1.HistogramQueryResult.HistogramEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::Histogram - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/histogram.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::Histogram;

    my $msg = Google::Cloud::Contentwarehouse::V1::Histogram::HistogramQuery->new({
        histogram_query => $histogram_query,
        require_precise_result_size => $require_precise_result_size,
        filters => $filters,
    });

    # Read or update a field
    my $val = $msg->histogram_query();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::Histogram::HistogramQuery->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/histogram.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::Histogram::HistogramQuery

The histogram request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->histogram_query() >> / C<< $msg->histogram_query($value) >>

Type: C<String>

An expression specifies a histogram request against matching documents for
searches.

See
[SearchDocumentsRequest.histogram_queries][google.cloud.contentwarehouse.v1.SearchDocumentsRequest.histogram_queries]
for details about syntax.

=item * C<< $msg->require_precise_result_size() >> / C<< $msg->require_precise_result_size($value) >>

Type: C<Bool>

Controls if the histogram query requires the return of a precise count.
Enable this flag may adversely impact performance.

Defaults to true.

=item * C<< $msg->filters() >> / C<< $msg->filters($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Histogram::HistogramQueryPropertyNameFilter>)

Optional. Filter the result of histogram query by the property names. It
only works with histogram query count('FilterableProperties'). It is an
optional. It will perform histogram on all the property names for all the
document schemas. Setting this field will have a better performance.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Histogram::HistogramQueryPropertyNameFilter

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document_schemas() >> / C<< $msg->document_schemas($value) >>

Type: C<String>

This filter specifies the exact document schema(s)
[Document.document_schema_name][google.cloud.contentwarehouse.v1.Document.document_schema_name]
to run histogram query against. It is optional. It will perform histogram
for property names for all the document schemas if it is not set.

At most 10 document schema names are allowed.
Format:
projects/{project_number}/locations/{location}/documentSchemas/{document_schema_id}.

=item * C<< $msg->property_names() >> / C<< $msg->property_names($value) >>

Type: C<String>

It is optional. It will perform histogram for all the property names if it
is not set.
The properties need to be defined with the is_filterable flag set to
true and the name of the property should be in the format:
"schemaId.propertyName". The property needs to be defined in the schema.
Example: the schema id is abc. Then the name of property for property
MORTGAGE_TYPE will be "abc.MORTGAGE_TYPE".

=item * C<< $msg->y_axis() >> / C<< $msg->y_axis($value) >>

Type: C<Enum> (L<Google::Cloud::Contentwarehouse::V1::HistogramQueryPropertyNameFilter::HistogramYAxis>)

By default, the y_axis is HISTOGRAM_YAXIS_DOCUMENT if this field is not
set.

=back

=head3 Enum: HistogramQueryPropertyNameFilter::HistogramYAxis

=over 4

=item * C<HISTOGRAM_YAXIS_DOCUMENT> => C<0>

=item * C<HISTOGRAM_YAXIS_PROPERTY> => C<1>

=back

=head2 Google::Cloud::Contentwarehouse::V1::Histogram::HistogramQueryResult

Histogram result that matches
[HistogramQuery][google.cloud.contentwarehouse.v1.HistogramQuery] specified
in searches.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->histogram_query() >> / C<< $msg->histogram_query($value) >>

Type: C<String>

Requested histogram expression.

=item * C<< $msg->histogram() >> / C<< $msg->histogram($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Histogram::HistogramQueryResult::HistogramEntry>)

A map from the values of the facet associated with distinct values to the
number of matching entries with corresponding value.

The key format is:

* (for string histogram) string values stored in the field.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::Histogram::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
