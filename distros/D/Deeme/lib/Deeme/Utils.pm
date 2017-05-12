package Deeme::Utils;
use base qw(Exporter);
use B::Deparse;
use MIME::Base64 qw( encode_base64  decode_base64);

our @EXPORT_OK = qw (_serialize _deserialize);
our $deparse   = B::Deparse->new;

sub _serialize   { encode_base64( $deparse->coderef2text(shift) ); }
sub _deserialize { eval( "sub " . decode_base64(shift) ); }
1;
