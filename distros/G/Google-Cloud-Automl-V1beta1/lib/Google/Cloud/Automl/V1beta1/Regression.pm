package Google::Cloud::Automl::V1beta1::Regression;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvcmVncmVzc2lvbi5wcm90bxIbZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MWJldGExIqQCChtSZWdyZXNzaW9uRXZhbHVhdGlvbk1ldHJpY3MS
NQoXcm9vdF9tZWFuX3NxdWFyZWRfZXJyb3IYASABKAJSFHJvb3RNZWFuU3F1YXJlZEVycm9y
Ei4KE21lYW5fYWJzb2x1dGVfZXJyb3IYAiABKAJSEW1lYW5BYnNvbHV0ZUVycm9yEkMKHm1l
YW5fYWJzb2x1dGVfcGVyY2VudGFnZV9lcnJvchgDIAEoAlIbbWVhbkFic29sdXRlUGVyY2Vu
dGFnZUVycm9yEhsKCXJfc3F1YXJlZBgEIAEoAlIIclNxdWFyZWQSPAobcm9vdF9tZWFuX3Nx
dWFyZWRfbG9nX2Vycm9yGAUgASgCUhdyb290TWVhblNxdWFyZWRMb2dFcnJvckKqAQofY29t
Lmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMUIPUmVncmVzc2lvblByb3RvWjdjbG91ZC5n
b29nbGUuY29tL2dvL2F1dG9tbC9hcGl2MWJldGExL2F1dG9tbHBiO2F1dG9tbHBiygIbR29v
Z2xlXENsb3VkXEF1dG9NbFxWMWJldGEx6gIeR29vZ2xlOjpDbG91ZDo6QXV0b01MOjpWMWJl
dGExSpMKCgYSBA4AKgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACQKCAoBCBIDEwBOCgkKAggLEgMTAE4KCAoBCBIDFAAwCgkKAggIEgMUADAKCAoBCBID
FQA4CgkKAggBEgMVADgKCAoBCBIDFgA4CgkKAggpEgMWADgKCAoBCBIDFwA3CgkKAggtEgMX
ADcKLgoCBAASBBoAKgEaIiBNZXRyaWNzIGZvciByZWdyZXNzaW9uIHByb2JsZW1zLgoKCgoD
BAABEgMaCCMKOwoEBAACABIDHAIkGi4gT3V0cHV0IG9ubHkuIFJvb3QgTWVhbiBTcXVhcmVk
IEVycm9yIChSTVNFKS4KCgwKBQQAAgAFEgMcAgcKDAoFBAACAAESAxwIHwoMCgUEAAIAAxID
HCIjCjYKBAQAAgESAx8CIBopIE91dHB1dCBvbmx5LiBNZWFuIEFic29sdXRlIEVycm9yIChN
QUUpLgoKDAoFBAACAQUSAx8CBwoMCgUEAAIBARIDHwgbCgwKBQQAAgEDEgMfHh8KcgoEBAAC
AhIDIwIrGmUgT3V0cHV0IG9ubHkuIE1lYW4gYWJzb2x1dGUgcGVyY2VudGFnZSBlcnJvci4g
T25seSBzZXQgaWYgYWxsIGdyb3VuZCB0cnV0aAogdmFsdWVzIGFyZSBhcmUgcG9zaXRpdmUu
CgoMCgUEAAICBRIDIwIHCgwKBQQAAgIBEgMjCCYKDAoFBAACAgMSAyMpKgomCgQEAAIDEgMm
AhYaGSBPdXRwdXQgb25seS4gUiBzcXVhcmVkLgoKDAoFBAACAwUSAyYCBwoMCgUEAAIDARID
JggRCgwKBQQAAgMDEgMmFBUKOAoEBAACBBIDKQIoGisgT3V0cHV0IG9ubHkuIFJvb3QgbWVh
biBzcXVhcmVkIGxvZyBlcnJvci4KCgwKBQQAAgQFEgMpAgcKDAoFBAACBAESAykIIwoMCgUE
AAIEAxIDKSYnYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::Regression::RegressionEvaluationMetrics ===
    # Fields for RegressionEvaluationMetrics
    # Field: root_mean_squared_error Type: 2 ()
    # Field: mean_absolute_error Type: 2 ()
    # Field: mean_absolute_percentage_error Type: 2 ()
    # Field: r_squared Type: 2 ()
    # Field: root_mean_squared_log_error Type: 2 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::Regression - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/regression.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::Regression;

    my $msg = Google::Cloud::Automl::V1beta1::Regression::RegressionEvaluationMetrics->new({
        root_mean_squared_error => $root_mean_squared_error,
        mean_absolute_error => $mean_absolute_error,
        mean_absolute_percentage_error => $mean_absolute_percentage_error,
        r_squared => $r_squared,
    });

    # Read or update a field
    my $val = $msg->root_mean_squared_error();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::Regression::RegressionEvaluationMetrics->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/regression.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::Regression::RegressionEvaluationMetrics

Metrics for regression problems.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->root_mean_squared_error() >> / C<< $msg->root_mean_squared_error($value) >>

Type: C<Float>

Output only. Root Mean Squared Error (RMSE).

=item * C<< $msg->mean_absolute_error() >> / C<< $msg->mean_absolute_error($value) >>

Type: C<Float>

Output only. Mean Absolute Error (MAE).

=item * C<< $msg->mean_absolute_percentage_error() >> / C<< $msg->mean_absolute_percentage_error($value) >>

Type: C<Float>

Output only. Mean absolute percentage error. Only set if all ground truth
values are are positive.

=item * C<< $msg->r_squared() >> / C<< $msg->r_squared($value) >>

Type: C<Float>

Output only. R squared.

=item * C<< $msg->root_mean_squared_log_error() >> / C<< $msg->root_mean_squared_log_error($value) >>

Type: C<Float>

Output only. Root mean squared log error.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::Regression::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
