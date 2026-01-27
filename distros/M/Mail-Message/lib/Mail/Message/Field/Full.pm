# This code is part of Perl distribution Mail-Message version 4.03.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Field::Full;{
our $VERSION = '4.03';
}

use parent 'Mail::Message::Field';

use strict;
use warnings;
use utf8;

use Log::Report       'mail-message', import => [ qw/__x error warning/ ];

use Encode            ();
use MIME::QuotedPrint ();
use Storable          qw/dclone/;

use Mail::Message::Field::Addresses    ();
use Mail::Message::Field::AuthResults  ();
#use Mail::Message::Field::AuthRecChain ();
use Mail::Message::Field::Date         ();
use Mail::Message::Field::DKIM         ();
use Mail::Message::Field::Structured   ();
use Mail::Message::Field::Unstructured ();
use Mail::Message::Field::URIs         ();

my $atext      = q[a-zA-Z0-9!#\$%&'*+\-\/=?^_`{|}~];  # from RFC5322
my $utf8_atext = q[\p{Alnum}!#\$%&'*+\-\/=?^_`{|}~];  # from RFC5335
my $atext_ill  = q/\[\]/;     # illegal, but still used (esp spam)

#--------------------

use overload '""' => sub { shift->decodedBody };

#--------------------

my %implementation;

BEGIN {
	$implementation{$_} = 'Addresses'    for qw/from to sender cc bcc reply-to envelope-to resent-from resent-to
				resent-cc resent-bcc resent-reply-to resent-sender x-beenthere errors-to mail-follow-up x-loop
				delivered-to original-sender x-original-sender/;
	$implementation{$_} = 'URIs'         for qw/list-help list-post list-subscribe list-unsubscribe list-archive list-owner/;
	$implementation{$_} = 'Structured'   for qw/content-disposition content-type content-id/;
	$implementation{$_} = 'Date'         for qw/date resent-date/;
	$implementation{$_} = 'AuthResults'  for qw/authentication-results/;
	$implementation{$_} = 'DKIM'         for qw/dkim-signature/;
#   $implementation{$_} = 'AuthRecChain' for qw/arc-authentication-results arc-message-signature arc-seal/;
}

sub new($;$$@)
{	my $class  = shift;
	my $name   = shift;
	my $body   = @_ % 2 ? shift : undef;
	my %args   = @_;

	$body      = delete $args{body} if defined $args{body};
	unless(defined $body)
	{	(my $n, $body) = split /\s*\:\s*/s, $name, 2;
		$name = $n if defined $body;
	}

	$class eq __PACKAGE__
		or return $class->SUPER::new(%args, name => $name, body => $body);

	# Look for best class to suit this field
	my $myclass = 'Mail::Message::Field::' . ($implementation{lc $name} || 'Unstructured');

	$myclass->SUPER::new(%args, name => $name, body => $body);
}

sub init($)
{	my ($self, $args) = @_;

	$self->SUPER::init($args);
	$self->{MMFF_name} = $args->{name};
	my $body           = $args->{body};

		if(!defined $body || !length $body || ref $body) { ; } # no body yet
	elsif(index($body, "\n") >= 0)
	     { $self->foldedBody($body) }        # body is already folded
	else { $self->unfoldedBody($body) }      # body must be folded

	$self;
}

sub clone() { dclone(shift) }
sub name()  { lc shift->{MMFF_name}}
sub Name()  { $_[0]->{MMFF_name} }

sub folded()
{	my $self = shift;
	wantarray or return $self->{MMFF_name}.':'.$self->foldedBody;

	my @lines = $self->foldedBody;
	my $first = $self->{MMFF_name}. ':'. shift @lines;
	($first, @lines);
}

sub unfoldedBody($;$)
{	my ($self, $body) = (shift, shift);

	if(defined $body)
	{	$self->foldedBody(scalar $self->fold($self->{MMFF_name}, $body));
		return $body;
	}

	$self->foldedBody =~ s/\r?\n(\s)/$1/gr =~ s/\r?\n/ /gr =~  s/^\s+//r =~ s/\s+$//r;
}

sub foldedBody($)
{	my ($self, $body) = @_;

	if(@_==2)
	{	$self->parse($body);
		$body =~ s/^\s*/ /m;
		$self->{MMFF_body} = $body;
	}
	elsif(defined($body = $self->{MMFF_body})) { ; }
	else
	{	# Create a new folded body from the parts.
		$self->{MMFF_body} = $body = $self->fold($self->{MMFF_name}, $self->produceBody);
	}

	wantarray ? (split /^/, $body) : $body;
}

#--------------------

sub from($@)
{	my ($class, $field) = (shift, shift);
	defined $field ? $class->new($field->Name, $field->foldedBody, @_) : ();
}

#--------------------

sub decodedBody()
{	my $self = shift;
	$self->decode($self->unfoldedBody, @_);
}

#--------------------

sub createComment($@)
{	my ($thing, $comment) = (shift, shift);

	$comment = $thing->encode($comment, @_) if @_; # encoding required...

	# Correct dangling parenthesis
	local $_ = $comment;               # work with a copy
	s#\\[()]#xx#g;                     # remove escaped parens
	s#[^()]#x#g;                       # remove other chars
	while( s#\(([^()]*)\)#x$1x# ) {;}  # remove pairs of parens

	substr($comment, CORE::length($_), 0, '\\')
		while s#[()][^()]*$##;         # add escape before remaining parens

	$comment =~ s#\\+$##;              # backslash at end confuses
	"($comment)";
}


sub createPhrase($)
{	my $self = shift;
	local $_ = shift;

	# I do not case whether it gets a but sloppy in the header string,
	# as long as it is functionally correct: no folding inside phrase quotes.
	return $_ = $self->encode($_, @_, force => 1)
		if length $_ > 50;

	$_ = $self->encode($_, @_) if @_;  # encoding required...

	if( m/[^$atext]/ )
	{	s#\\#\\\\#g;
		s#"#\\"#g;
		$_ = qq["$_"];
	}

	$_;
}


sub beautify() { $_[0] }

#--------------------

sub _mime_word($$) { "$_[0]$_[1]?=" }
sub _encode_b($)   { MIME::Base64::encode_base64(shift, '')  }

sub _encode_q($)   # RFC2047 sections 4.2 and 5
{	my $chunk = shift;
	$chunk =~ s#([^a-zA-Z0-9!*+/_ -])#sprintf "=%02X", ord $1#ge;
	$chunk =~ s#([_\?,"])#sprintf "=%02X", ord $1#ge;
	$chunk =~ s/ /_/g;     # special case for =? ?= use
	$chunk;
}

sub encode($@)
{	my ($self, $utf8, %args) = @_;

	my ($charset, $lang, $encoding);

	if($charset = $args{charset})
	{	warning __x"illegal character in charset '{name}'.", name => $charset
			if $charset =~ m/[\x00-\ ()<>@,;:"\/[\]?.=\\]/;
	}
	else
	{	$charset = $utf8 =~ /\P{ASCII}/ ? 'utf8' : 'us-ascii';
	}

	if($lang = $args{language})
	{	warning __x"illegal character in language '{name}'.", name => $lang
			if $lang =~ m/[\x00-\ ()<>@,;:"\/[\]?.=\\]/;
	}

	if($encoding = $args{encoding})
	{	unless($encoding =~ m/^[bBqQ]$/ )
		{	warning __x"illegal encoding '{name}', using 'q'.", name => $encoding;
			$encoding = 'q';
		}
	}
	else { $encoding = 'q' }

	my $name  = $args{name};
	my $lname = defined $name ? length($name)+1 : 0;

	return $utf8
		if lc($encoding) eq 'q'
		&& length $utf8 < 70
		&& ($utf8 =~ m/\A[\p{IsASCII}]+\z/ms && !$args{force});

	my $pre = '=?'. $charset. ($lang ? '*'.$lang : '') .'?'.$encoding.'?';

	my @result;
	if(lc($encoding) eq 'q')
	{	my $chunk  = '';
		my $llen = 73 - length($pre) - $lname;

		while(length(my $chr = substr($utf8, 0, 1, '')))
		{	$chr  = _encode_q Encode::encode($charset, $chr, 0);
			if(bytes::length($chunk) + bytes::length($chr) > $llen)
			{	push @result, _mime_word($pre, $chunk);
				$chunk = '';
				$llen = 73 - length $pre;
			}
			$chunk .= $chr;
		}
		push @result, _mime_word($pre, $chunk)
			if length($chunk);
	}
	else
	{	my $chunk  = '';
		my $llen = int((73 - length($pre) - $lname) / 4) * 3;
		while(length(my $chr = substr($utf8, 0, 1, '')))
		{	my $chr = Encode::encode($charset, $chr, 0);
			if(bytes::length($chunk) + bytes::length($chr) > $llen)
			{	push @result, _mime_word($pre, _encode_b($chunk));
				$chunk = '';
				$llen  = int((73 - length $pre) / 4) * 3;
			}
			$chunk .= $chr;
		}
		push @result, _mime_word($pre, _encode_b($chunk))
			if length $chunk;
	}

	join ' ', @result;
}


sub _decoder($$$)
{	my ($charset, $encoding, $encoded) = @_;
	$charset   =~ s/\*[^*]+$//;   # language component not used
	my $to_utf8 = Encode::find_encoding($charset || 'us-ascii');
	$to_utf8 or return $encoded;

	my $decoded;
	if($encoding !~ /\S/)
	{	$decoded = $encoded;
	}
	elsif(lc($encoding) eq 'q')
	{	# Quoted-printable encoded specific to mime-fields
		$decoded = MIME::QuotedPrint::decode_qp($encoded =~ s/_/ /gr);
	}
	elsif(lc($encoding) eq 'b')
	{	# Base64 encoded
		require MIME::Base64;
		$decoded = MIME::Base64::decode_base64($encoded);
	}
	else
	{	# unknown encodings ignored
		return $encoded;
	}

	$to_utf8->decode($decoded, Encode::FB_DEFAULT);  # error-chars -> '?'
}

sub decode($@)
{	my $thing   = shift;
	my @encoded = split /(\=\?[^?\s]*\?[bqBQ]?\?[^?]*\?\=)/, shift;
	@encoded or return '';

	my %args    = @_;

	my $is_text = exists $args{is_text} ? $args{is_text} : 1;
	my @decoded = shift @encoded;

	while(@encoded)
	{	shift(@encoded) =~ /\=\?([^?\s]*)\?([^?\s]*)\?([^?]*)\?\=/;
		push @decoded, _decoder $1, $2, $3;

		@encoded or last;

		# in text, blanks between encoding must be removed, but otherwise kept
		if($is_text && $encoded[0] !~ m/\S/) { shift @encoded }
		else { push @decoded, shift @encoded }
	}

	join '', @decoded;
}

#--------------------

sub parse($) { $_[0] }


sub consumePhrase($)
{	my ($thing, $string) = @_;

	my $phrase;
	if($string =~ s/^\s*\" ((?:[^"\r\n\\]*|\\.)*) (?:\"|\s*$)//x )
	{	($phrase = $1) =~ s/\\\"/"/g;
	}
	elsif($string =~ s/^\s*((?:\=\?.*?\?\=|[${utf8_atext}${atext_ill}\ \t.])+)//o )
	{	($phrase = $1) =~ s/\s+$//;
		CORE::length($phrase) or undef $phrase;
	}

	defined $phrase ? ($thing->decode($phrase), $string) : (undef, $string);
}


sub consumeComment($)
{	my ($thing, $string) = @_;
	# Backslashes are officially not permitted in comments, but not everyone
	# knows that.  Nested parens are supported.

	$string =~ s/^\s* \( ((?:\\.|[^)])*) (?:\)|$) //x
		or return (undef, $string);    # allow unterminated comments

	my $comment = $1;

	# Continue consuming characters until we have balanced parens, for
	# nested comments which are permitted.
	while(1)
	{	(my $count = $comment) =~ s/\\./xx/g;
		last if +( $count =~ tr/(// ) == ( $count =~ tr/)// );

		last if $string !~ s/^((?:\\.|[^)])*) \)//x;  # cannot satisfy

		$comment .= ')'.$1;
	}

	for($comment)
	{	s/^\s+//;
		s/\s+$//;
		s/\\ ( [()] )/$1/gx; # Remove backslashes before nested comment.
	}

	($comment, $string);
}


sub consumeDotAtom($)
{	my ($self, $string) = @_;
	my ($atom, $comment);

	while(1)
	{	(my $c, $string) = $self->consumeComment($string);
		if(defined $c) { $comment .= $c; next }

		$string =~ s/^\s*([$atext]+(?:\.[$atext]+)*)//o
			or last;

		$atom .= $1;
	}

	($atom, $string, $comment);
}


sub produceBody() { $_[0]->{MMFF_body} }

#--------------------


1;
