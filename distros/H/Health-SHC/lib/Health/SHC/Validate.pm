use strict;
use warnings;

# ABSTRACT: Validate and return data from a Smart Card URL

package Health::SHC::Validate;

our $VERSION = '0.002';

#use IO::Uncompress::RawInflate qw/ rawinflate /;
#use MIME::Base64 qw/ decode_base64url /;
use Crypt::JWT qw(decode_jwt);
use JSON::Parse qw(read_json);
use File::ShareDir qw(dist_file);

=head1 NAME

Health::SHC::Validate - Validate the Signature of the Smart Health Card data

=head1 SYNOPSIS

    use Health::SHC::Validate;

    my $shc_valid = Health::SHC::Validate->new();
    my $data = $shc_valid->get_valid_data($qr, $keys_json);

=cut

=head1 DESCRIPTION

This perl module validates the signature of the JSON Web Token containing the
Smart Health Card data.

=cut

=head1 PREREQUISITES

=over

=item * L<Crypt::JWT>

=item * L<JSON::Parse>

=back

=cut

=head2 METHODS

=head3 B<new(...)>

Constructor; see OPTIONS above.

=cut

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;
}

=head3 B<get_valid_data($shc)>

Validates the signature of the Smart Health Card URI data from the
QR code and returns a hash of the valid data.

Arguments:
    $shc:     string Smart Health Card (shc:/) URI
    $keys:    string filename of custom keys in JSON format

Returns: hash  of data from the shc:/ data

=cut

sub get_valid_data {
    my $self = shift;
    my $shc  = shift;
    my $keys = shift;

    $shc =~ s/shc:\///g;
    my @elements = $shc =~ m/(..)/g;

    my $str;
    my $i = 0;
    foreach my $a (@elements) {
        $str .= chr($a + 45);
    }

    #my @tokens = split('\.', $str);

    #my $header = decode_base64url($tokens[0]);
    #my $payload = decode_base64url($tokens[1]);
    #my $signature = decode_base64url($tokens[2]);

    #my $request = '';
    #rawinflate \$payload => \$request;

    my $k;
    if ( (defined $keys) && (-e $keys)) {
        $k = read_json ($keys);
    } else {
        my $keyfile = dist_file('Health-SHC', 'keys.json');
        if ( ! -e $keyfile ) {
            return;
        }

        $k = read_json ($keyfile);
    }

    return decode_jwt(token=>$str,kid_keys=>$k);
}
1;
