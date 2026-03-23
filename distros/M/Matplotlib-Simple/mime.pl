#!/usr/bin/env perl

use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Matplotlib::Simple;
use JSON::MaybeXS;
use MIME::Base64;
use File::Temp;

sub write_data {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ( ref $args ne 'HASH' ) {
	  die "args must be given as a hash ref, e.g. \"$current_sub({ data => ... })\"";
	}
	my @reqd_args = (
	  'data', # args to original function (scalar, hashref, or arrayref)
	  'fh',   # file handle
	  'name'  # python variable name
	);
	my @undef_args = grep { not defined $args->{$_} } @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die "the above args are required for $current_sub, but weren't defined";
	}
	# 1. Create the JSON Encoder; allow_nonref: allows scalars (strings/numbers) to be encoded
	my $json_encoder = JSON::MaybeXS->new->utf8->allow_nonref;
	# 2. Serialize Perl Data -> JSON String; Passing data directly. JSON::MaybeXS handles refs + scalars automatically.
	my $json_string = $json_encoder->encode($args->{data});
	# 3. Base64 Encode the JSON String, not the reference
	my $b64_data = encode_base64($json_string, ''); 
	# Assign the b64 string to a temp python variable
	say {$args->{fh}} "$args->{name}_b64 = '$b64_data'";
	# Decode b64 -> bytes -> utf8 string -> json load -> python object
	say {$args->{fh}} "$args->{name} = json.loads(base64.b64decode($args->{name}_b64).decode('utf-8'))";
}
say length join (',', 0..999);
my $fh = File::Temp->new(DIR => '/tmp', SUFFIX => '.py', UNLINK => 0);
write_data({
	data => [0..999],
	fh   => $fh,
	name => 'arr'
});
close $fh;
say $fh->filename;
