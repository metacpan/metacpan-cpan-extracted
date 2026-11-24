package Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
CkZnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvbWVyY2hhbnRfY2VudGVyX2FjY291bnRf
bGlua19zZXJ2aWNlLnByb3RvEhtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEaHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
Gj5nb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvbWVyY2hhbnRfY2VudGVyX2FjY291bnRf
bGluay5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aG2dvb2ds
ZS9wcm90b2J1Zi9lbXB0eS5wcm90byJmCiVMaXN0TWVyY2hhbnRDZW50ZXJBY2NvdW50TGlu
a3NSZXF1ZXN0Ej0KBnBhcmVudBgBIAEoCUIl4EEC+kEfCh1yZXRhaWwuZ29vZ2xlYXBpcy5j
b20vQ2F0YWxvZ1IGcGFyZW50IqMBCiZMaXN0TWVyY2hhbnRDZW50ZXJBY2NvdW50TGlua3NS
ZXNwb25zZRJ5Ch1tZXJjaGFudF9jZW50ZXJfYWNjb3VudF9saW5rcxgBIAMoCzI2Lmdvb2ds
ZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5NZXJjaGFudENlbnRlckFjY291bnRMaW5rUhptZXJj
aGFudENlbnRlckFjY291bnRMaW5rcyLlAQomQ3JlYXRlTWVyY2hhbnRDZW50ZXJBY2NvdW50
TGlua1JlcXVlc3QSPQoGcGFyZW50GAEgASgJQiXgQQL6QR8KHXJldGFpbC5nb29nbGVhcGlz
LmNvbS9DYXRhbG9nUgZwYXJlbnQSfAocbWVyY2hhbnRfY2VudGVyX2FjY291bnRfbGluaxgC
IAEoCzI2Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5NZXJjaGFudENlbnRlckFjY291
bnRMaW5rQgPgQQJSGW1lcmNoYW50Q2VudGVyQWNjb3VudExpbmsidQomRGVsZXRlTWVyY2hh
bnRDZW50ZXJBY2NvdW50TGlua1JlcXVlc3QSSwoEbmFtZRgBIAEoCUI34EEC+kExCi9yZXRh
aWwuZ29vZ2xlYXBpcy5jb20vTWVyY2hhbnRDZW50ZXJBY2NvdW50TGlua1IEbmFtZTL+Bwog
TWVyY2hhbnRDZW50ZXJBY2NvdW50TGlua1NlcnZpY2USigIKHkxpc3RNZXJjaGFudENlbnRl
ckFjY291bnRMaW5rcxJCLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5MaXN0TWVyY2hh
bnRDZW50ZXJBY2NvdW50TGlua3NSZXF1ZXN0GkMuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFs
cGhhLkxpc3RNZXJjaGFudENlbnRlckFjY291bnRMaW5rc1Jlc3BvbnNlIl+C0+STAlASTi92
MmFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qfS9tZXJj
aGFudENlbnRlckFjY291bnRMaW5rc9pBBnBhcmVudBKhAwofQ3JlYXRlTWVyY2hhbnRDZW50
ZXJBY2NvdW50TGluaxJDLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5DcmVhdGVNZXJj
aGFudENlbnRlckFjY291bnRMaW5rUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVy
YXRpb24imQKC0+STAm4iTi92MmFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9jYXRhbG9ncy8qfS9tZXJjaGFudENlbnRlckFjY291bnRMaW5rczocbWVyY2hhbnRfY2Vu
dGVyX2FjY291bnRfbGlua9pBI3BhcmVudCxtZXJjaGFudF9jZW50ZXJfYWNjb3VudF9saW5r
ykF8CjVnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuTWVyY2hhbnRDZW50ZXJBY2NvdW50
TGluaxJDZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkNyZWF0ZU1lcmNoYW50Q2VudGVy
QWNjb3VudExpbmtNZXRhZGF0YRLdAQofRGVsZXRlTWVyY2hhbnRDZW50ZXJBY2NvdW50TGlu
axJDLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5EZWxldGVNZXJjaGFudENlbnRlckFj
Y291bnRMaW5rUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJdgtPkkwJQKk4vdjJh
bHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovbWVyY2hhbnRD
ZW50ZXJBY2NvdW50TGlua3MvKn3aQQRuYW1lGknKQRVyZXRhaWwuZ29vZ2xlYXBpcy5jb23S
QS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQukBCh9j
b20uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhQiVNZXJjaGFudENlbnRlckFjY291bnRM
aW5rU2VydmljZVByb3RvUAFaN2Nsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyYWxw
aGEvcmV0YWlscGI7cmV0YWlscGKiAgZSRVRBSUyqAhtHb29nbGUuQ2xvdWQuUmV0YWlsLlYy
QWxwaGHKAhtHb29nbGVcQ2xvdWRcUmV0YWlsXFYyYWxwaGHqAh5Hb29nbGU6OkNsb3VkOjpS
ZXRhaWw6OlYyYWxwaGFK9h8KBxIFDgCLAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoC
AwMSAxUAIwoJCgIDBBIDFgBICgkKAgMFEgMXAC0KCQoCAwYSAxgAJQoICgEIEgMaADgKCQoC
CCUSAxoAOAoICgEIEgMbAE4KCQoCCAsSAxsATgoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEI
EgMdAEYKCQoCCAgSAx0ARgoICgEIEgMeADgKCQoCCAESAx4AOAoICgEIEgMfACQKCQoCCCQS
Ax8AJAoICgEIEgMgADgKCQoCCCkSAyAAOAoICgEIEgMhADcKCQoCCC0SAyEANwpZCgIGABIE
JABQARpNIE1lcmNoYW50IENlbnRlciBMaW5rIHNlcnZpY2UgdG8gbGluayBhIEJyYW5jaCB0
byBhIE1lcmNoYW50IENlbnRlciBBY2NvdW50LgoKCgoDBgABEgMkCCgKCgoDBgADEgMlAj0K
DAoFBgADmQgSAyUCPQoLCgMGAAMSBCYCJzcKDQoFBgADmggSBCYCJzcKuwEKBAYAAgASBCwC
MgMarAEgTGlzdHMgYWxsCiBbTWVyY2hhbnRDZW50ZXJBY2NvdW50TGlua11bZ29vZ2xlLmNs
b3VkLnJldGFpbC52MmFscGhhLk1lcmNoYW50Q2VudGVyQWNjb3VudExpbmtdcwogdW5kZXIg
dGhlIHNwZWNpZmllZCBwYXJlbnQgW0NhdGFsb2ddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJh
bHBoYS5DYXRhbG9nXS4KCgwKBQYAAgABEgMsBiQKDAoFBgACAAISAywlSgoMCgUGAAIAAxID
LQ81Cg0KBQYAAgAEEgQuBDAGChEKCQYAAgAEsMq8IhIELgQwBgoMCgUGAAIABBIDMQQ0Cg8K
CAYAAgAEmwgAEgMxBDQKbgoEBgACARIENgJCAxpgIENyZWF0ZXMgYQogW01lcmNoYW50Q2Vu
dGVyQWNjb3VudExpbmtdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5NZXJjaGFudENl
bnRlckFjY291bnRMaW5rXS4KCgwKBQYAAgEBEgM2BiUKDAoFBgACAQISAzYmTAoMCgUGAAIB
AxIDNw8rCg0KBQYAAgEEEgQ4BDsGChEKCQYAAgEEsMq8IhIEOAQ7BgoNCgUGAAIBBBIEPAQ9
LgoQCggGAAIBBJsIABIEPAQ9LgoNCgUGAAIBBBIEPgRBBgoPCgcGAAIBBJkIEgQ+BEEGCoUC
CgQGAAICEgRJAk8DGvYBIERlbGV0ZXMgYQogW01lcmNoYW50Q2VudGVyQWNjb3VudExpbmtd
W2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5NZXJjaGFudENlbnRlckFjY291bnRMaW5r
XS4KIElmIHRoZQogW01lcmNoYW50Q2VudGVyQWNjb3VudExpbmtdW2dvb2dsZS5jbG91ZC5y
ZXRhaWwudjJhbHBoYS5NZXJjaGFudENlbnRlckFjY291bnRMaW5rXQogdG8gZGVsZXRlIGRv
ZXMgbm90IGV4aXN0LCBhIE5PVF9GT1VORCBlcnJvciBpcyByZXR1cm5lZC4KCgwKBQYAAgIB
EgNJBiUKDAoFBgACAgISA0kmTAoMCgUGAAICAxIDSg8kCg0KBQYAAgIEEgRLBE0GChEKCQYA
AgIEsMq8IhIESwRNBgoMCgUGAAICBBIDTgQyCg8KCAYAAgIEmwgAEgNOBDIKwwEKAgQAEgRV
AF0BGrYBIFJlcXVlc3QgZm9yCiBbTWVyY2hhbnRDZW50ZXJBY2NvdW50TGlua1NlcnZpY2Uu
TGlzdE1lcmNoYW50Q2VudGVyQWNjb3VudExpbmtzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYy
YWxwaGEuTWVyY2hhbnRDZW50ZXJBY2NvdW50TGlua1NlcnZpY2UuTGlzdE1lcmNoYW50Q2Vu
dGVyQWNjb3VudExpbmtzXQogbWV0aG9kLgoKCgoDBAABEgNVCC0KngEKBAQAAgASBFkCXAQa
jwEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgQ2F0YWxvZyBvZiB0aGUgcmVzb3VyY2UuCiBJdCBt
dXN0IG1hdGNoIHRoaXMgZm9ybWF0OgogYHByb2plY3RzL3tQUk9KRUNUX05VTUJFUn0vbG9j
YXRpb25zL2dsb2JhbC9jYXRhbG9ncy97Q0FUQUxPR19JRH1gCgoMCgUEAAIABRIDWQIICgwK
BQQAAgABEgNZCQ8KDAoFBAACAAMSA1kSEwoNCgUEAAIACBIEWRRcAwoPCggEAAIACJwIABID
WgQqCg4KBwQAAgAInwgSA1sETwrEAQoCBAESBGIAZQEatwEgUmVzcG9uc2UgZm9yCiBbTWVy
Y2hhbnRDZW50ZXJBY2NvdW50TGlua1NlcnZpY2UuTGlzdE1lcmNoYW50Q2VudGVyQWNjb3Vu
dExpbmtzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuTWVyY2hhbnRDZW50ZXJBY2Nv
dW50TGlua1NlcnZpY2UuTGlzdE1lcmNoYW50Q2VudGVyQWNjb3VudExpbmtzXQogbWV0aG9k
LgoKCgoDBAEBEgNiCC4KGQoEBAECABIDZAJHGgwgVGhlIGxpbmtzLgoKDAoFBAECAAQSA2QC
CgoMCgUEAQIABhIDZAskCgwKBQQBAgABEgNkJUIKDAoFBAECAAMSA2RFRgrFAQoCBAISBGoA
fQEauAEgUmVxdWVzdCBmb3IKIFtNZXJjaGFudENlbnRlckFjY291bnRMaW5rU2VydmljZS5D
cmVhdGVNZXJjaGFudENlbnRlckFjY291bnRMaW5rXVtnb29nbGUuY2xvdWQucmV0YWlsLnYy
YWxwaGEuTWVyY2hhbnRDZW50ZXJBY2NvdW50TGlua1NlcnZpY2UuQ3JlYXRlTWVyY2hhbnRD
ZW50ZXJBY2NvdW50TGlua10KIG1ldGhvZC4KCgoKAwQCARIDagguCrEBCgQEAgIAEgRuAnEE
GqIBIFJlcXVpcmVkLiBUaGUgYnJhbmNoIHJlc291cmNlIHdoZXJlIHRoaXMgTWVyY2hhbnRD
ZW50ZXJBY2NvdW50TGluayB3aWxsIGJlCiBjcmVhdGVkLiBGb3JtYXQ6CiBgcHJvamVjdHMv
e1BST0pFQ1RfTlVNQkVSfS9sb2NhdGlvbnMvZ2xvYmFsL2NhdGFsb2dzL3tDQVRBTE9HX0lE
fWAKCgwKBQQCAgAFEgNuAggKDAoFBAICAAESA24JDwoMCgUEAgIAAxIDbhITCg0KBQQCAgAI
EgRuFHEDCg8KCAQCAgAInAgAEgNvBCoKDgoHBAICAAifCBIDcARPCtsCCgQEAgIBEgR7Anwv
GswCIFJlcXVpcmVkLiBUaGUKIFtNZXJjaGFudENlbnRlckFjY291bnRMaW5rXVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyYWxwaGEuTWVyY2hhbnRDZW50ZXJBY2NvdW50TGlua10KIHRvIGNy
ZWF0ZS4KCiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byBjcmVh
dGUgdGhlCiBbTWVyY2hhbnRDZW50ZXJBY2NvdW50TGlua11bZ29vZ2xlLmNsb3VkLnJldGFp
bC52MmFscGhhLk1lcmNoYW50Q2VudGVyQWNjb3VudExpbmtdLAogcmVnYXJkbGVzcyBvZiB3
aGV0aGVyIG9yIG5vdCBpdCBleGlzdHMsIGEgUEVSTUlTU0lPTl9ERU5JRUQgZXJyb3IgaXMK
IHJldHVybmVkLgoKDAoFBAICAQYSA3sCGwoMCgUEAgIBARIDexw4CgwKBQQCAgEDEgN7OzwK
DAoFBAICAQgSA3wGLgoPCggEAgIBCJwIABIDfActCscBCgIEAxIGggEAiwEBGrgBIFJlcXVl
c3QgZm9yCiBbTWVyY2hhbnRDZW50ZXJBY2NvdW50TGlua1NlcnZpY2UuRGVsZXRlTWVyY2hh
bnRDZW50ZXJBY2NvdW50TGlua11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLk1lcmNo
YW50Q2VudGVyQWNjb3VudExpbmtTZXJ2aWNlLkRlbGV0ZU1lcmNoYW50Q2VudGVyQWNjb3Vu
dExpbmtdCiBtZXRob2QuCgoLCgMEAwESBIIBCC4KwAEKBAQDAgASBoUBAooBBBqvASBSZXF1
aXJlZC4gRnVsbCByZXNvdXJjZSBuYW1lLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3Rf
bnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxvZ19pZH0v
bWVyY2hhbnRDZW50ZXJBY2NvdW50TGlua3Mve21lcmNoYW50X2NlbnRlcl9hY2NvdW50X2xp
bmtfaWR9YAoKDQoFBAMCAAUSBIUBAggKDQoFBAMCAAESBIUBCQ0KDQoFBAMCAAMSBIUBEBEK
DwoFBAMCAAgSBoUBEooBAwoQCggEAwIACJwIABIEhgEEKgoRCgcEAwIACJ8IEgaHAQSJAQVi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksRequest ===
    # Fields for ListMerchantCenterAccountLinksRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksResponse ===
    # Fields for ListMerchantCenterAccountLinksResponse
    # Field: merchant_center_account_links Type: 11 (.google.cloud.retail.v2alpha.MerchantCenterAccountLink)

# === Message: Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::CreateMerchantCenterAccountLinkRequest ===
    # Fields for CreateMerchantCenterAccountLinkRequest
    # Field: parent Type: 9 ()
    # Field: merchant_center_account_link Type: 11 (.google.cloud.retail.v2alpha.MerchantCenterAccountLink)

# === Message: Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::DeleteMerchantCenterAccountLinkRequest ===
    # Fields for DeleteMerchantCenterAccountLinkRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::MerchantCenterAccountLinkServiceClient ===
package Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::MerchantCenterAccountLinkServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::MerchantCenterAccountLinkServiceClient

Client stub representing the remote C<MerchantCenterAccountLinkService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub list_merchant_center_account_links {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.MerchantCenterAccountLinkService',
        method         => 'ListMerchantCenterAccountLinks',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksResponse',
    });
}

sub create_merchant_center_account_link {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::CreateMerchantCenterAccountLinkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.MerchantCenterAccountLinkService',
        method         => 'CreateMerchantCenterAccountLink',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_merchant_center_account_link {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::DeleteMerchantCenterAccountLinkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.MerchantCenterAccountLinkService',
        method         => 'DeleteMerchantCenterAccountLink',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/merchant_center_account_link_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService;

    my $msg = Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksRequest->new({
        parent => $parent,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/merchant_center_account_link_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksRequest

Request for
[MerchantCenterAccountLinkService.ListMerchantCenterAccountLinks][google.cloud.retail.v2alpha.MerchantCenterAccountLinkService.ListMerchantCenterAccountLinks]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent Catalog of the resource.
It must match this format:
`projects/{PROJECT_NUMBER}/locations/global/catalogs/{CATALOG_ID}`

=back

=head2 Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksResponse

Response for
[MerchantCenterAccountLinkService.ListMerchantCenterAccountLinks][google.cloud.retail.v2alpha.MerchantCenterAccountLinkService.ListMerchantCenterAccountLinks]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->merchant_center_account_links() >> / C<< $msg->merchant_center_account_links($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::MerchantCenterAccountLink>)

The links.

=back

=head2 Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::CreateMerchantCenterAccountLinkRequest

Request for
[MerchantCenterAccountLinkService.CreateMerchantCenterAccountLink][google.cloud.retail.v2alpha.MerchantCenterAccountLinkService.CreateMerchantCenterAccountLink]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The branch resource where this MerchantCenterAccountLink will be
created. Format:
`projects/{PROJECT_NUMBER}/locations/global/catalogs/{CATALOG_ID}`

=item * C<< $msg->merchant_center_account_link() >> / C<< $msg->merchant_center_account_link($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::MerchantCenterAccountLink>)

Required. The
[MerchantCenterAccountLink][google.cloud.retail.v2alpha.MerchantCenterAccountLink]
to create.

If the caller does not have permission to create the
[MerchantCenterAccountLink][google.cloud.retail.v2alpha.MerchantCenterAccountLink],
regardless of whether or not it exists, a PERMISSION_DENIED error is
returned.

=back

=head2 Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::DeleteMerchantCenterAccountLinkRequest

Request for
[MerchantCenterAccountLinkService.DeleteMerchantCenterAccountLink][google.cloud.retail.v2alpha.MerchantCenterAccountLinkService.DeleteMerchantCenterAccountLink]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/merchantCenterAccountLinks/{merchant_center_account_link_id}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
