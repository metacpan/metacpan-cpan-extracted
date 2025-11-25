# This code is part of Perl distribution Mail-Message version 3.019.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Body;{
our $VERSION = '3.019';
}

use base 'Mail::Reporter';

use strict;
use warnings;
use utf8;

use Carp;
use MIME::Types    ();
use File::Basename qw/basename/;
use Encode         qw/find_encoding from_to encode_utf8/;
use List::Util     qw/first/;
use Scalar::Util   qw/blessed/;

use Mail::Message::Field        ();
use Mail::Message::Field::Full  ();

# http://www.iana.org/assignments/character-sets
use Encode::Alias;
define_alias(qr/^unicode-?1-?1-?utf-?([78])$/i => '"UTF-$1"');  # rfc1642

my $mime_types;

#--------------------

#--------------------

sub charsetDetectAlgorithm(;$)
{	my $self = shift;
	$self->{MMBE_det} = shift if @_;
	$self->{MMBE_det} || 'charsetDetect';
}

#--------------------

sub _char_enc($)
{	my ($self, $charset) = @_;
	return undef if !$charset || $charset eq 'PERL';

	my $enc = find_encoding $charset
		or $self->log(WARNING => "Charset `$charset' is not known.");

	$enc;
}

sub encode(@)
{	my ($self, %args) = @_;
	my $bodytype  = $args{result_type} || ref $self;

	### The content type

	my $type_from = $self->type;
	my $type_to   = $args{mime_type}   || $type_from->clone->study;
	blessed $type_to
		or $type_to = Mail::Message::Field::Full->new('Content-Type' => $type_to);

	### Detect specified transfer-encodings

	my $transfer  = $args{transfer_encoding} || $self->transferEncoding->clone;
	blessed $transfer
		or $transfer = Mail::Message::Field->new('Content-Transfer-Encoding' => $transfer);

	my $trans_was = lc $self->transferEncoding;
	my $trans_to  = lc $transfer;

	### Detect specified charsets

	my $is_text   = $type_from =~ m!^text/!i;
	my ($char_was, $char_to, $from, $to);

	if($is_text)
	{	$char_was = $type_from->attribute('charset');  # sometimes missing
		$char_to  = $type_to->attribute('charset');    # usually missing

		if(my $charset = delete $args{charset})
		{	# Explicitly stated output charset
			if(!$char_to || $char_to ne $charset)
			{	$char_to = $charset;
				$type_to->attribute(charset => $char_to);
			}
		}
		elsif(!$char_to && $char_was)
		{	# By default, do not change charset
			$char_to = $char_was;
			$type_to->attribute(charset => $char_to);
		}

		if($char_to && $trans_to ne 'none' && $char_to eq 'PERL')
		{	# We cannot leave the body into the 'PERL' charset when transfer-encoding is applied.
			$self->log(WARNING => "Content-Transfer-Encoding `$trans_to' requires explicit charset, defaulted to utf-8");
			$char_to = 'utf-8';
		}

		$from = $self->_char_enc($char_was);
		$to   = $self->_char_enc($char_to);

		if($from && $to)
		{	if($char_was ne $char_to && $from->name eq $to->name)
			{	# modify source charset into a different alias
				$type_from->attribute(charset => $char_to);
				$char_was = $char_to;
				$from     = $to;
			}

			return $self
				if $trans_was eq $trans_to && $char_was eq $char_to;
		}
	}
	elsif($trans_was eq $trans_to)
	{	# No changes needed;
		return $self;
	}

	### Apply transfer-decoding

	my $decoded;
	if($trans_was eq 'none')
	{	$decoded = $self }
	elsif(my $decoder = $self->getTransferEncHandler($trans_was))
	{	$decoded = $decoder->decode($self, result_type => $bodytype) }
	else
	{	$self->log(WARNING => "No decoder defined for transfer encoding $trans_was.");
		return $self;
	}

	### Apply character-set recoding

	my $recoded;
	if($is_text)
	{	unless($char_was)
		{	# When we do not know the character-sets, try to auto-detect
			my $auto = $args{charset_detect} || $self->charsetDetectAlgorithm;
			$char_was = $decoded->$auto;
			$from     = $self->_char_enc($char_was);
			$decoded->type->attribute(charset => $char_was);

			unless($char_to)
			{	$char_to = $char_was;
				$type_to->attribute(charset => $char_to);
				$to      = $from;
			}
		}

		my $text = $decoded->string;
		my $new_data
		  = $to   && $char_was eq 'PERL' ? $to->encode($text)
		  : $from && $char_to  eq 'PERL' ? $from->decode($text)
		  : $to && $from && $char_was ne $char_to ? $to->encode($from->decode($text))
		  : undef;

		$recoded
		  = $new_data
		  ? $bodytype->new(based_on => $decoded, data => $new_data, mime_type => $type_to, checked => 1)
		  : $decoded;
	}
	else
	{	$recoded = $decoded;
	}

	### Apply transfer-encoding

	my $trans;
	if($trans_to ne 'none')
	{	$trans = $self->getTransferEncHandler($trans_to)
			or $self->log(WARNING => "No encoder defined for transfer encoding `$trans_to'.");
	}

	defined $trans ? $trans->encode($recoded, result_type => $bodytype) : $recoded;
}


sub charsetDetect(%)
{	my ($self, %args) = @_;
	my $text = $self->string;

	# Flagged as UTF8, so certainly created by the Perl program itself:
	# the content is not octets.
	if(utf8::is_utf8($text))
	{	$args{external} or return 'PERL';
		$text = encode_utf8 $text;
	}

	# Only look for normal characters, first 1920 unicode characters
	# When there is any octet in 'utf-encoding'-space, but not an
	# legal utf8, than it's not utf8.
	return 'utf-8'
		if $text =~ m/ [\xC0-\xDF][\x80-\xBF]    # 110xxxxx, 10xxxxxx
					| [\xE0-\xEF][\x80-\xBF]{2} # 1110xxxx, (10xxxxxx)²
					| [\xF0-\xF7][\x80-\xBF]{3} # 11110xxx, (10xxxxxx)3
					/x
		&& $text !~ m/[\xC0-\xFF][^\x80-\xBF]/
		&& $text !~ m/[\xC0-\xFF]\z/;

	# Produce 'us-ascii' when it suffices: it is the RFC compliant
	# default charset.
	$text =~ m/[\x80-\xFF]/ ? 'cp1252' : 'us-ascii';
}


sub check()
{	my $self     = shift;
	return $self if $self->checked;
	my $eol      = $self->eol;

	my $encoding = $self->transferEncoding->body;
	return $self->eol($eol)
		if $encoding eq 'none';

	my $encoder  = $self->getTransferEncHandler($encoding);
	my $checked  = $encoder ? $encoder->check($self)->eol($eol) : $self->eol($eol);
	$checked->checked(1);
	$checked;
}


sub encoded(%)
{	my ($self, %args) = @_;
	my $mime    = $self->mimeType;

	if($mime->isBinary)
	{	return $self->transferEncoding eq 'none' ? $self->encode(transfer_encoding => $mime->encoding) : $self->check;
	}

	my $charset = my $old_charset = $self->charset || '';
	if(!$charset || $charset eq 'PERL')
	{	my $auto = $args{charset_detect} || $self->charsetDetectAlgorithm;
		$charset = $self->$auto(external => 1);
	}

	my $enc_was = $self->transferEncoding;
	my $enc     = $enc_was eq 'none' ? $mime->encoding : $enc_was;

	$enc_was eq $enc && $old_charset eq $charset
	  ? $self->check
	  : $self->encode(transfer_encoding => $enc, charset => $charset);
}


my $native_eol = $^O =~ m/^win/i ? 'CRLF' : $^O =~ m/^mac/i ? 'CR' : 'LF';

sub eol(;$)
{	my $self = shift;
	my $old_eol = $self->{MMBE_eol} ||= $native_eol;
	@_ or return $old_eol;

	my $eol  = shift;
	$eol     = $native_eol if $eol eq 'NATIVE';

	$eol ne $old_eol || !$self->checked
		or return $self;

	my $lines = $self->lines;

	my $wrong
	  = $eol eq 'CRLF' ? first { !/\015\012$/ } @$lines
	  : $eol eq 'CR'   ? first { !/\015$/ } @$lines
	  : $eol eq 'LF'   ? first { /\015\012$|\015$/ } @$lines
	  : ($self->log(WARNING => "Unknown line terminator $eol ignored"), 1);

	$wrong
		or return $self;

	my $expect = $eol eq 'CRLF' ? "\015\012" : $eol eq 'CR' ? "\015" : "\012";
	my @new    = map s/[\015\012]+$/$expect/r, @$lines;
	(ref $self)->new(based_on => $self, eol => $eol, data => \@new);
}


sub unify($)
{	my ($self, $body) = @_;
	return $self if $self==$body;

	my $mime     = $self->type;
	my $transfer = $self->transferEncoding;
	my $encoded  = $body->encode(mime_type => $mime, transfer_encoding => $transfer);

	# Encode makes the best of it, but is it good enough?
	$mime eq $encoded->type && $transfer eq $encoded->transferEncoding ? $encoded : undef;
}

#--------------------

sub isBinary()
{	my $self = shift;
	$mime_types ||= MIME::Types->new(only_complete => 1);
	my $type = $self->type                    or return 1;
	my $mime = $mime_types->type($type->body) or return 1;
	$mime->isBinary;
}


sub isText() { not shift->isBinary }


sub dispositionFilename(;$)
{	my $self = shift;
	my $raw;

	my $field;
	if($field = $self->disposition)
	{	$field = $field->study if $field->can('study');
		$raw   = $field->attribute('filename') || $field->attribute('file') || $field->attribute('name');
	}

	if(!defined $raw && ($field = $self->type))
	{	$field = $field->study if $field->can('study');
		$raw   = $field->attribute('filename') || $field->attribute('file') || $field->attribute('name');
	}

	my $base;
	if(!defined $raw || !length $raw) {}
	elsif(index($raw, '?') >= 0)
	{	eval 'require Mail::Message::Field::Full';
		$base = Mail::Message::Field::Full->decode($raw);
	}
	else
	{	$base = $raw;
	}

	@_ or return $base;

	my $dir      = shift;
	my $filename = '';
	if(defined $base)   # RFC6266 section 4.3, very safe
	{	$filename = basename $base =~ s/\s+/ /gr =~ s/ $//r =~ s/^ //r =~ s/[^\w .-]//gr;
	}

	my ($filebase, $ext) = length $filename && $filename =~ m/(.*)\.([^.]+)/ ? ($1, $2)
	: (part => ($self->mimeType->extensions)[0] || 'raw');

	my $fn = File::Spec->catfile($dir, "$filebase.$ext");

	for(my $unique = 1; -e $fn; $unique++)
	{	$fn = File::Spec->catfile($dir, "$filebase-$unique.$ext");
	}

	$fn;
}

#--------------------

my %transfer_encoder_classes = (
	'base64'  => 'Mail::Message::TransferEnc::Base64',
	'binary'  => 'Mail::Message::TransferEnc::Binary',
	'8bit'    => 'Mail::Message::TransferEnc::EightBit',
	'quoted-printable' => 'Mail::Message::TransferEnc::QuotedPrint',
	'7bit'    => 'Mail::Message::TransferEnc::SevenBit',
);

my %transfer_encoders;   # they are reused.

sub getTransferEncHandler($)
{	my ($self, $type) = @_;

	return $transfer_encoders{$type}
		if exists $transfer_encoders{$type};   # they are reused.

	my $class = $transfer_encoder_classes{$type}
		or return;

	eval "require $class";
	confess "Cannot load $class: $@\n" if $@;

	$transfer_encoders{$type} = $class->new;
}


sub addTransferEncHandler($$)
{	my ($this, $name, $what) = @_;

	my $class;
	if(ref $what)
	{	$transfer_encoders{$name} = $what;
		$class = ref $what;
	}
	else
	{	delete $transfer_encoders{$name};
		$class = $what;
	}

	$transfer_encoder_classes{$name} = $class;
	$this;
}

1;
