package Lingua::JA::Mail::Header;

our $VERSION = '0.02'; # 2003-04-03 (since 2003-03-05)

use 5.008;
use strict;
use warnings;
use Carp;

use Encode;
use MIME::Base64;

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
	return $self;
}

sub set {
	my ($self, $entity, $value) = @_;
	$$self{$entity} = $value;
	return $self;
}

sub build {
	my $self = shift;
	my @key = $self->_header_order;
	my @header;
	foreach my $key (@key) {
		push(@header, "$key: $$self{$key}");
	}
	return join("\n", @header);
}

sub _header_order {
	my $self = shift;
	my @key = keys(%$self);
	my @order = qw(
		Date From Sender Reply-To To Cc Bcc
		Message-ID In-Reply-To References
		Subject Comments Keywords
	);
	
	my @newkey;
	foreach my $order (@order) {
		foreach my $key (@key) {
			if ($key eq $order) {
				push(@newkey, $key);
			}
		}
	}
	
	my @oldkey;
	foreach my $key (@key) {
		my $exist = 0;
		foreach my $newkey (@newkey) {
			if ($key eq $newkey) {
				$exist = 1;
				last;
			}
		}
		if ($exist != 1) {
			push(@oldkey, $key);
		}
	}
	
	return @newkey, @oldkey;
}
########################################################################
# specify the origination date.
sub date {
	my($self, $date_time) = @_;
	$$self{'Date'} = $date_time;
	return $self;
}
########################################################################
# add a originator address or a destination address.
sub add_from {
	my($self, $addr_spec, $name) = @_;
	$self->_add_mailbox('From', $addr_spec, $name);
	return $self
}

sub sender {
	my($self, $addr_spec, $name) = @_;
	$self->_add_mailbox('Sender', $addr_spec, $name);
	return $self
}

sub add_reply {
	my($self, $addr_spec, $name) = @_;
	$self->_add_mailbox('Reply-To', $addr_spec, $name);
	return $self
}

sub add_to {
	my($self, $addr_spec, $name) = @_;
	$self->_add_mailbox('To', $addr_spec, $name);
	return $self
}

sub add_cc {
	my($self, $addr_spec, $name) = @_;
	$self->_add_mailbox('Cc', $addr_spec, $name);
	return $self
}

sub add_bcc {
	my($self, $addr_spec, $name) = @_;
	$self->_add_mailbox('Bcc', $addr_spec, $name);
	return $self
}

sub _add_mailbox {
	my($self, $field, $addr_spec, $name) = @_;
	
	my $address;
	if ($name) {
		if ( _check_if_contain_japanese($name) ) {
			my $name = encoded_header($name);
			$address = "$name\n <$addr_spec>";
		}
		else {
			if ( length($name) <= 73) {
				$address = "\"$name\"\n <$addr_spec>";
			}
            else {
				my @name = split(/ /, $name);
				my $too_long_word = 0;
				foreach my $piece (@name) {
					if ( length($piece) > 75 ) {
						$too_long_word = 1;
						last;
					}
				}
				if ($too_long_word) {
					$name = encoded_header_ascii($name);
					$address = "$name\n <$addr_spec>";
				}
				else {
					$name = join("\n ", @name);
					$address = "$name\n <$addr_spec>";
				}
			}
		}
	}
	else {
		$address = $addr_spec;
	}
	
	if ($$self{$field}) {
		if ($field eq 'Sender') {
			croak "a violation of the RFC2822 - you can specify the 'Sender:' field with only one 'mailbox'";
		}
        else {
			$$self{$field} = "$$self{$field},\n $address";
		}
	}
	else {
		$$self{$field} = "\n $address";
    }
	
	return $self;
}
########################################################################
sub _check_if_contain_japanese {
	my $string = shift;
	
#	$string = decode('utf8', $string);
	$string =~ tr/\n//d; # ignore line-break
	return $string =~
		tr/\x01-\x08\x0B\x0C\x0E-\x1F\x7F\x21\x23-\x5B\x5D-\x7E\x20//c;
	# this tr/// checks if there is other than qtext characters or SPACE.
	# from RFC2822:
	# qtext = NO-WS-CTL / %d33 / %d35-91 / %d93-126
	# qcontent = qtext / quoted-pair
	# quoted-string = [CFWS] DQUOTE *([FWS] qcontent) [FWS] DQUOTE [CFWS]
}
########################################################################
sub subject {
	my($self, $string) = @_;
	$$self{'Subject'} = encoded_header($string);
	$$self{'Subject'} = "\n $$self{'Subject'}";
	return $self;
}
########################################################################

# RFC2822 describes about the length of a line
# Max: 998 = 1000 - (CR + LF)
# Rec:  76 =   78 - (CR + LF)
# RFC2047 describes about the length of an encoded-word
# Max:  75 =   76 - SPACE

sub encoded_header {
	my ($string) = @_;
	
	my @lines = _encoded_word($string);
	
	my $line = join("\n ", @lines);
	return $line;
}

# an encoded-word is composed of
# 'charset', 'encoding', 'encoded-text' and delimiters.
# Hence the max length of an encoded-text is:
# 75 - ('charset', 'encoding' and delimiters)
# 
# charset 'ISO-2022-JP' is 11.
# encoding 'B' is 1.
# delimiters '=?', '?', '?' and '?=' is total 6.
# 75 - (11 + 1 + 6) = 57
# It is said that the max length of an encoded-text is 57
# when we use ISO-2022-JP B encoding.

sub _encoded_word {
	my ($string) = @_;
	
	my @words = _encoded_text($string);
	
	foreach my $word (@words) {
		$word = "=?ISO-2022-JP?B?$word?=";
	}
	
	return @words;
}

# Through Base64 encoding, a group of 4 ASCII-6bit characters
# is generated by 3 ASCII-8bit pre-encode characters.
# We can get 14 group of encoded 4 ASCII-6bit characters under
# the encoded-text's 57 characters limit.
# Hence, we may handle max 42 ASCII-8bit characters as
# a pre-encode text.
# So we should split a ISO-2022-JP text that
# each splitted piece's length is within 42
# if it is counted as ASCII-8bit characters.

sub _encoded_text {
	my ($string) = @_;
	
	my @text = _split($string);
	
	foreach my $text (@text) {
		$text = encode_base64($text);
		$text =~ tr/\n//d;
	}
	
	return @text;
}

sub _split {
	my ($string) = @_;
	
	my @strings;
	while ($string) {
		(my $piece, $string) = _cut_once($string);
		push(@strings, $piece);
	}
	
	return @strings;
}

sub _cut_once {
	my ($string) = @_;
	
	my $whole = encode('iso-2022-jp', $string);
	if ( length($whole) <= 42 ) {
		return $whole;
		last;
	}
	
	my $letters = length($string);
	for (my $i = 1; $i <= $letters; $i++) {
		my $temp = substr($string, 0, $i);
		$temp = encode('iso-2022-jp', $temp);
		if (length($temp) > 42) {
			my $piece = substr($string, 0, $i - 1);
			$piece = encode('iso-2022-jp', $piece);
			my $rest  = substr($string, $i - 1);
			return ($piece, $rest);
			last;
		}
	}
}
########################################################################
sub encoded_header_ascii {
	my ($string) = @_;
	
	my @lines = _encoded_word_q($string);
	
	my $line = join("\n ", @lines);
	return $line;
}

sub _encoded_word_q {
	my ($string) = @_;
	
	my @words = _encoded_text_q($string);
	
	foreach my $word (@words) {
		$word = "=?US-ASCII?Q?$word?=";
	}
	
	return @words;
}

sub _encoded_text_q {
	my ($string) = @_;
	
	my @text = _split_q($string);
	
	foreach my $text (@text) {
		$text = encode_q($text);
	}
	
	return @text;
}

sub _split_q {
	my ($string) = @_;
	
	my @strings;
	while ($string) {
		(my $piece, $string) = _cut_once_q($string);
		push(@strings, $piece);
	}
	
	return @strings;
}

sub _cut_once_q {
	my ($string) = @_;
	
	my $whole = encode_q($string);
	if ( length($whole) <= 60 ) {
		return $string;
		last;
	}
	
	my $letters = length($string);
	for (my $i = 1; $i <= $letters; $i++) {
		my $temp = substr($string, 0, $i);
		$temp = encode_q($temp);
		if (length($temp) > 60) {
			my $piece = substr($string, 0, $i - 1);
			my $rest  = substr($string, $i - 1);
			return ($piece, $rest);
			last;
		}
	}
}

sub encode_q {
	my ($string) = @_;
	
	$string =~
		s/([^\x21\x23-\x3C\x3E\x40-\x5B\x5D\x5E\x60-\x7E])/uc sprintf("=%02x", ord($1))/eg;
	
	return $string;
}


1;
__END__

=head1 NAME

Lingua::JA::Mail::Header - build ISO-2022-JP charset 'B' encoding mail header fields

=head1 SYNOPSIS

 use utf8;
 use Lingua::JA::Mail::Header;
 
 $header = Lingua::JA::Mail::Header->new;
 
 $header->add_from('taro@cpan.tld', 'YAMADA, Taro');
 
 # display-name is omitted:
  $header->add_to('kaori@cpan.tld');
 # with a display-name in the US-ASCII characters:
  $header->add_to('sakura@cpan.tld', 'Sakura HARUNO');
 # with a display-name contains Japanese characters:
  $header->add_to('yuri@cpan.tld', 'NAME CONTAINING JAPANESE CHARS');
 
 # mail subject contains Japanese characters:
  $header->subject('SUBJECT CONTAINING JAPANESE CHARS');
 
 # build and output the header fields
  print $header->build;

=head1 DESCRIPTION

This module enables you to build mail header fields from a string which may contain some Japanese characters.

If a string can contain Japanese characters, it will be encoded with 'ISO-2022-JP' charset 'B' encoding.

=head1 METHODS

=over

=item new

Create a new object.

=item date($date_time)

This method specifies the origination C<date-time> of the mail (C<Date:> header field). The format of C<date-time> should be compliant to the RFC2822 specification. For example:
     
 Mon, 10 Mar 2003 18:48:06 +0900

Although RFC2822 describes that the origination date field and the originator address field(s) are the only required header fields, this module would not care to omit those header fields. Since MTA may modify such omittions and you would intended to do.

=item add_from($addr_spec [, $display_name])

This method specifies a originator address (the C<From:> header field). The $addr_spec must be valid as an C<addr-spec> in the RFC2822 specification. Be careful, an C<addr-spec> doesn't include the surrounding tokens "<" and ">" (angles).

The $display_name is optional value. It must be valid as an C<display-name> in the RFC2822 specification. It can contain Japanese characters and then it will be encoded with 'B' encoding. When it contains only US-ASCII characters, it will not normaly be encoded. But in the rare case, it might be encoded with 'Q' encoding to shorten line length less than 76 characters (excluding CR LF).

You can use repeatedly this method as much as you wish to specify more than one address. And then you B<must> specify the one C<Sender:> header address.

Although RFC2822 describes that the origination date field and the originator address field(s) are the only required header fields, this module would not care to omit those header fields. Since MTA may modify such omittions and you would intended to do.

=item sender($addr_spec [, $display_name])

This method specifies the sender address (the C<Sender:> header field). You can specify only one address of this header.

=item add_reply($addr_spec [, $display_name])

It is basically same as C<add_from()> but specifies the C<Reply-To:> header field.

=item add_to($addr_spec [, $display_name])

This method specifies a destination address (the C<To:> header field). The $addr_spec must be valid as an C<addr-spec> in the RFC2822 specification. Be careful, an C<addr-spec> doesn't include the surrounding tokens "<" and ">" (angles).

The $display_name is optional value. It must be valid as an C<display-name> in the RFC2822 specification. It can contain Japanese characters and then it will be encoded with 'B' encoding. When it contains only US-ASCII characters, it will not normaly be encoded. But in the rare case, it might be encoded with 'Q' encoding to shorten line length less than 76 characters (excluding CR LF).

You can use repeatedly this method as much as you wish to specify more than one address.

=item add_cc($addr_spec [, $display_name])

It is basically same as C<add_to()> but specifies the C<Cc:> header field.

=item add_bcc($addr_spec [, $display_name])

It is basically same as C<add_to()> but specifies the C<Bcc:> header field.

=item subject($unstructured)

This method specifies the mail subject (C<Suject:> header field). The $unstructured is valid as an C<unstructured> in the RFC2822 specification. It can contain Japanese characters.

=item build

Build and return the header fields.

=item set($entity, $value)

You can add a free-style header directly with this method. For example, if you want to specify the C<X-Mailer:> header field with value of 'Perl 5.8.0':

 $header->set('X-Mailer', 'Perl 5.8.0');

However, when you use this method, you must be in conformity with the RFC2822 specification by yourself.

=back

=head1 SEE ALSO

=over

=item module: L<Lingua::JA::Mail>

=item RFC2822: L<http://www.ietf.org/rfc/rfc2822.txt> (Mail)

=item RFC2047: L<http://www.ietf.org/rfc/rfc2047.txt> (MIME)

=item RFC1468: L<http://www.ietf.org/rfc/rfc1468.txt> (ISO-2022-JP)

=item module: L<MIME::Base64>

=item module: L<Encode>

=back

=head1 NOTES

This module runs under Unicode/UTF-8 environment (hence Perl5.8 or later is required), you should input octets with UTF-8 charset. Please C<use utf8;> pragma to enable to detect strings as UTF-8 in your source code.

=head1 AUTHOR

Masanori HATA E<lt>lovewing@geocities.co.jpE<gt> (Saitama, JAPAN)

=head1 COPYRIGHT

Copyright (c) 2003 Masanori HATA. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
