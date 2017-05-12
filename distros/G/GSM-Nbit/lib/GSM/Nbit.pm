package GSM::Nbit;

use warnings;
use strict;
use Carp qw(cluck);

=head1 NAME

GSM::Nbit - GSM 7bit and 8bit data encoder and decoder.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

GSM::Nbit

Throughout GSM world "special" encodings called 7bit and 8bit are used.
Encoding in 8bit is just plain HEX value and is provided here for completeness
and ease of use, 7bit packs 8bit data into 7bit HEX value by limiting it to the
lower 127 characters - and hence gaining 1 extra char every 8 characters.

That's how you get 160 characters limit on plain text (ASCII + few Greek chars)
messages with only 140 bytes for data.

Since many modules need such encodings in them, those functions are refactored
here. It's released as separate module and not part of some other distribution
exactly for that reason.

=head1 Code Sample

	use Encode qw/encode decode/;
	use GSM::Nbit;

	my $gsm = GSM::Nbit->new();
	my $txt	= "some text";
	
	# We need to encode it first - for details see:
	# http://www.dreamfabric.com/sms/default_alphabet.html
	my $txt0338 = encode("gsm0338", $txt); 
	my $txt_7bit = $gsm->encode_7bit_wlen($txt);
	
	# ... we submit it to the GSM network
	# ... latter we receive something from GSM network
	
	my $txt_gsm	= $gsm->decode_7bit_wlen($txt_7bit);
	
	# we need to decode it back to computer/Perl representation
	my $txt_orig = decode("gsm0338", $txt_gsm); 

=head1 METHODS

=head2 new

This is the constructor. Accepts no params.

=cut

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	return $self;
}

=head2 encode_7bit

This function encodes the string as 7bit packed data in HEX representation.
Please note that you probably need to convert the text into gsm0338 format first -
we don't automatically do that.

For details see L<http://www.dreamfabric.com/sms/default_alphabet.html>.

You can use Perl's Encode module for that - see:
L<http://search.cpan.org/perldoc?Encode::GSM0338>

=cut

sub encode_7bit {
    my($self, $data) = @_;
	return unless $data;
   
    my($bit_string, $message) = ('','');
    my($octet, $rest);

    for(split(//,$data)) {
        $bit_string.=unpack('b7',$_);
    }

    while(defined($bit_string) && (length($bit_string))) {
        $rest = $octet = substr($bit_string,0,8);
        $message .= unpack("H2",pack("b8",substr($octet.'0'x7,0,8)));
        $bit_string = (length($bit_string) > 8) ? substr($bit_string,8) : '';
    }
	
	return uc($message);
}

=head2 encode_7bit_wlen

Beside encoding the string as 7bit packed data in HEX representation, this
method also adds the length in front of the encoded string, it's needed in some
GSM protocols as a kind of checksum and to help with certain edge cases.

=cut

sub encode_7bit_wlen {
	my($self, $data) = @_;
	return '00' unless $data;
	
	my $text_7bit = $self->encode_7bit($data);
	
	return sprintf("%02X", length($data)).($text_7bit);
}

=head2 decode_7bit

This function decodes the 7bit data in HEX representation back to a "readable"
string. Second optional parameter is length - it's used in edge cases when
we can't be sure if the last seven 0's in bit representation are meant to
be @ sign, or it's a filler and there to just fit the 7bit representation into
8bit data computers (and cellphones) use.

Edge cases happen when length of original text is 7, 15, 23, 31 ... (+8) chars.

=cut

sub decode_7bit {
    my $self = shift();
    my $data = shift();
	
	return unless $data;
	
	my $length  = shift || undef;
    my $message = "";
    my $len     = length($data);
	
	my $bytes;
	my $i = 0;
	
	my $repeat = int(length($data)) / 2;
	
	for($i=0; $i < $repeat; $i++){
		my $hex = substr($data, $i * 2, 2);
		my $hex_b = unpack('b8',pack('H2', $hex));
		$bytes .= $hex_b;
	}
	
	$repeat = $length || int(length($bytes) / 7);
	my $last_loop = int(length($bytes) / 7) - 1;
	for($i = 0; $i < $repeat; $i++){
		my $letter = substr($bytes, ($i * 7), 7);
		if(($i == $last_loop) && ($letter eq '0000000') && (not defined $length)){
			cluck "Possible edge case, can't be sure if last character is " .
			      'really @ or just a filler.'
		}
		
		$message .= pack('b7', $letter);
	}
	
	return $message;
}

=head2 decode_7bit_wlen

This function decodes back to a "readable" text string the 7bit data in HEX
representation that includes the length as the first value.

=cut

sub decode_7bit_wlen {
	my($self, $data) = @_;
	
	unless($data){
		return;
	}

	if(length($data) < 2){
		cluck "Invalid data - must be at least 2 characters of HEX representation";
		return;
	}
	
	my $len = hex(substr($data,0,2));
	
	my $real_length = (length($data) / 2 * 8 / 7 ) - 2;
	if( $len <= $real_length){
		cluck "Something is wrong with the data you want me to decode, length " .
			 "indicates $len chars, but there aren't that much chars.";
		return;
	}
	# but then it shouldn't be too long for provided length either
	if($len + 1 <= $real_length){
		cluck "Provided length is much shorter than the actual length, ".
			  "something is probably wrong - but I'll continue...";
	}
	$data = substr($data, 2, length($data) - 2);
	
	my $message = $self->decode_7bit($data, $len);
	
	return $message;
}

=head2 encode_8bit

This function encodes the string as 8bit HEX representation of the string.

=cut

sub encode_8bit {
	my ($self, $data) = @_;
	return unless $data;
	
	my $message = "";

	while (length($data)) {
		$message .= sprintf("%.2X", ord(substr($data,0,1)));
		$data = substr($data,1);
	}
	
	return $message;
}

=head2 encode_8bit_wlen

This function encodes the string as 8bit HEX representation of the string
and also adds the length in front of the encoded string since it's needed in some
GSM protocols as a kind of checksum.

=cut

sub encode_8bit_wlen {
	my($self, $data) = @_;
	return '00' unless $data;
	
	my $text_8bit = $self->encode_8bit($data);
	
	return sprintf("%02X", length($data)).($text_8bit);
}

=head2 decode_8bit

This function decodes back to a "readable" text string the 8bit HEX representation
with length at the start of the string.

=cut

sub decode_8bit {
	my ($self, $data) = @_;
	return unless $data;
	
	my $message;

	while ( length($data) ) {
		$message .= pack('H2',substr($data,0,2));
		$data = substr($data,2);
	}
	
	return $message;
}

=head2 decode_8bit_wlen

This function decodes the 8bit HEX representation of the string back to
readable text string.

=cut

sub decode_8bit_wlen {
	my ($self, $data) = @_;
	return unless $data;

	my $len = hex(substr($data,0,2));
	$data = substr($data, 2, length($data) - 2);
	
	my $message = "";

	while ( length($data) ) {
		$message .= pack('H2',substr($data,0,2));
		$data = substr($data,2);
	}
	
	return $message;
}

=head1 INCOMPATIBILITIES

Note that you might need to update your Encode.pm module beforehand for tests
to pass (and to be able to use this in a meaningful way) since older version
had a bug for gsm0338 encode/decode of @ char.

=head1 AUTHOR

Aleksandar Petrovic, C<< <techcode at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gsm-nbit at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GSM-Nbit>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GSM::Nbit


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=GSM-Nbit>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/GSM-Nbit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/GSM-Nbit>

=item * Search CPAN

L<http://search.cpan.org/dist/GSM-Nbit/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Aleksandar Petrovic.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of GSM::Nbit
