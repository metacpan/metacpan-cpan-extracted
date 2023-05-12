# MIME::Mini - Minimal code to parse/create mbox files and mail messages
#
# Copyright (C) 2005-2007, 2023 raf <raf@raf.org>
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# 20230510 raf <raf@raf.org>

package MIME::Mini;
use 5.014;
use strict;
use warnings;

our $VERSION = '1.001';

use Exporter;
our @ISA = ('Exporter');

our @EXPORT = ();
our @EXPORT_OK = qw(
	formail mail2str mail2multipart mail2singlepart mail2mbox
	insert_header append_header replace_header delete_header
	insert_part append_part replace_part delete_part
	header headers header_names
	param mimetype encoding filename
	body message parts
	newparam newmail
);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

sub formail # rfc2822 + mboxrd format (see http://www.qmail.org/man/man5/mbox.html)
{
	sub mime # rfc2045, rfc2046
	{
		my ($mail, $parent) = @_;
		return $mail unless exists $mail->{header} && exists $mail->{header}->{'content-type'} || defined $parent && exists $parent->{mime_type} && $parent->{mime_type} =~ /^multipart\/digest$/i;
		my ($content_type) = (exists $mail->{header} && exists $mail->{header}->{'content-type'}) ? @{$mail->{header}->{'content-type'}} : "Content-Type: message/rfc822\n";
		my ($type) = $content_type =~ /^content-type:\s*([\w\/.-]+)/i;
		my $boundary = param($mail, 'content-type', 'boundary') if $type =~ /^multipart\//i;
		return $mail unless defined $type && ($type =~ /^multipart\//i && $boundary || $type =~ /^message\/rfc822$/i);
		($mail->{mime_boundary}) = $boundary =~ /^(.*\S)/ if $boundary;
		$mail->{mime_type} = $type;
		$mail->{mime_message} = mimepart(delete $mail->{body} || '', $mail), return $mail if $type =~ /^message\/(?:rfc822|external-body)$/i;
		return tnef2mime(mimeparts($mail, $parent));
	}

	sub mimeparts
	{
		my ($mail, $parent) = @_;
		my $state = 'preamble';
		my $text = '';

		for (split /(?<=\n)/, delete $mail->{body} || '')
		{
			if (/^--\Q$mail->{mime_boundary}\E(--)?/)
			{
				if ($state eq 'preamble')
				{
					$state = 'part';
					$mail->{mime_preamble} = $text if length $text;
				}
				elsif ($state eq 'part')
				{
					$state = 'epilogue' if defined $1 && $1 eq '--';
					push @{$mail->{mime_parts}}, mimepart($text, $mail);
				}

				$text = '', next;
			}

			$text .= $_;
		}

		push @{$mail->{mime_parts}}, mimepart($text, $mail) if $state eq 'part' && length $text;
		$mail->{mime_epilogue} = $text if $state eq 'epilogue' && length $text;
		return $mail;
	}

	sub mimepart
	{
		my ($mail, $parent) = @_;
		my @lines = split /(?<=\n)/, $mail;
		# Needed to cope (badly) when message/rfc822 attachments incorrectly start with /^From / (thanks libpst)
		@lines = ('') unless @lines;
		formail(sub { shift @lines }, sub { $mail = shift }, $parent);
		return $mail;
	}

	my ($rd, $act, $parent) = @_;
	my $state = 'header';
	my $mail; my $last;

	while (defined($_ = $rd->()))
	{
		s/\r(?=\n)//g; #, tr/\r/\n/;

		if (!defined $parent && /^From (?:\S+\s+)?\s*[a-zA-Z]+\s+[a-zA-Z]+\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}\s+(?:[A-Z]+\s+)?\d{4}/) # mbox header
		{
			$mail->{body} =~ s/\n\n\z/\n/ if $mail && exists $mail->{mbox} && exists $mail->{body};
			my $mbox = $_; $act->(mime($mail, $parent)) or return if $mail;
			$mail = { mbox => $mbox }, $state = 'header', undef $last, next;
		}

		if ($state eq 'header')
		{
			if (/^([\w-]+):/) # mail header
			{
				push @{$mail->{headers}}, $_;
				push @{$mail->{header}->{$last = lc $1}}, $_;
			}
			elsif (/^$/) # blank line after mail headers
			{
				$mail->{body} = '', $state = 'body';
			}
			else # mail header continuation or error
			{
				${$mail->{headers}}[$#{$mail->{headers}}] .= $_ if defined $last;
				${$mail->{header}->{$last}}[$#{$mail->{header}->{$last}}] .= $_ if defined $last;
			}
		}
		elsif ($state eq 'body')
		{
			s/^>(>*From )/$1/ if exists $mail->{mbox};
			$mail->{body} .= $_;
		}
	}

	$mail->{body} =~ s/\n\n\z/\n/ if $mail && exists $mail->{mbox} && exists $mail->{body};
	$act->(mime($mail, $parent)) if $mail;
}

sub mail2str
{
	my $mail = shift;
	my $head = '';
	$head .= $mail->{mbox} if exists $mail->{mbox};
	$head .= join '', @{$mail->{headers}} if exists $mail->{headers};
	my $body = '';
	$body .= $mail->{body} if exists $mail->{body};
	$body .= "$mail->{mime_preamble}" if exists $mail->{mime_preamble};
	$body .= "--$mail->{mime_boundary}\n" if exists $mail->{mime_boundary} && !exists $mail->{mime_parts};
	$body .= join('', map { "--$mail->{mime_boundary}\n" . mail2str($_) } @{$mail->{mime_parts}}) if exists $mail->{mime_parts};
	$body .= "--$mail->{mime_boundary}--\n" if exists $mail->{mime_boundary};
	$body .= "$mail->{mime_epilogue}" if exists $mail->{mime_epilogue};
	$body .= mail2str($mail->{mime_message}) if exists $mail->{mime_message};
	$body =~ s/^(>*From )/>$1/mg, $body =~ s/([^\n])\n?\z/$1\n\n/ if exists $mail->{mbox};
	return $head . "\n" . $body;
}

my $bchar = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'()+_,-.\/:=?";
sub mail2multipart
{
	my $m = shift;
	return $m if exists $m->{mime_type} && $m->{mime_type} =~ /^multipart\//i;
	my $p = {};
	append_header($p, $_) for grep { /^content-/i } @{$m->{headers}};
	$p->{body} = delete $m->{body} if exists $m->{body};
	$p->{mime_message} = delete $m->{mime_message} if exists $m->{mime_message};
	$p->{mime_type} = $m->{mime_type} if exists $m->{mime_type};
	$m->{mime_type} = 'multipart/mixed';
	$m->{mime_boundary} = exists $m->{mime_prev_boundary} ? delete $m->{mime_prev_boundary} : join '', map { substr $bchar, int(rand(length $bchar)), 1 } 0..30;
	$m->{mime_preamble} = delete $m->{mime_prev_preamble} if exists $m->{mime_prev_preamble};
	$m->{mime_epilogue} = delete $m->{mime_prev_epilogue} if exists $m->{mime_prev_epilogue};
	delete_header($m, qr/content-[^:]*/i);
	append_header($m, 'MIME-Version: 1.0') unless exists $m->{header} && exists $m->{header}->{'mime-version'};
	append_header($m, "Content-Type: $m->{mime_type}; boundary=\"$m->{mime_boundary}\"");
	$m->{mime_parts} = [$p];
	return $m;
}

sub mail2singlepart
{
	my $m = shift;
	$m->{mime_message} = mail2singlepart($m->{mime_message}), return $m if exists $m->{mime_type} && $m->{mime_type} =~ /^message\//i;
	return $m unless exists $m->{mime_type} && $m->{mime_type} =~ /^multipart\//i && @{$m->{mime_parts}} <= 1;
	my $p = shift @{$m->{mime_parts}};
	$m->{mime_prev_boundary} = delete $m->{mime_boundary} if exists $m->{mime_boundary};
	$m->{mime_prev_preamble} = delete $m->{mime_preamble} if exists $m->{mime_preamble};
	$m->{mime_prev_epilogue} = delete $m->{mime_epilogue} if exists $m->{mime_epilogue};
	$m->{body} = $p->{body} if exists $p->{body};
	$m->{mime_message} = $p->{mime_message} if exists $p->{mime_message};
	delete $m->{mime_type}; $m->{mime_type} = $p->{mime_type} if exists $p->{mime_type};
	delete $m->{mime_parts}; $m->{mime_parts} = $p->{mime_parts} if exists $p->{mime_parts};
	$m->{mime_boundary} = $p->{mime_boundary} if exists $p->{mime_boundary};
	$m->{mime_preamble} = $p->{mime_preamble} if exists $p->{mime_preamble};
	$m->{mime_epilogue} = $p->{mime_epilogue} if exists $p->{mime_epilogue};
	my $explicit = 0;
	delete_header($m, qr/content-[^:]*/i);
	append_header($m, $_), ++$explicit for grep { /^content-/i } @{$p->{headers}};
	delete_header($m, 'mime-version') unless $explicit;
	return mail2singlepart($m);
}

sub mail2mbox
{
	my $m = shift;
	return $m if exists $m->{mbox};
	my ($f) = header($m, 'sender');
	($f) = header($m, 'from') unless defined $f;
	$f =~ s/"(?:\\[^\r\n]|[^\\"])*"//g, $f =~ s/\s*;.*//, $f =~s/^[^:]+:\s*//, $f =~ s/\s*,.*$//, $f =~ s/^[^<]*<\s*//, $f =~ s/\s*>.*$// if defined $f;
	$f = 'unknown' unless defined $f;
	use POSIX; $m->{mbox} = "From $f  " . ctime(time());
	return $m;
}

sub insert_header
{
	my ($m, $h, $l, $c) = @_;
	$h = header_format($h, $l, $c);
	my ($n) = $h =~ /^([^:]+):/;
	unshift @{$m->{headers}}, $h;
	unshift @{$m->{header}->{lc $n}}, $h;
}

sub append_header
{
	my ($m, $h, $l, $c) = @_;
	$h = header_format($h, $l, $c);
	my ($n) = $h =~ /^([^:]+):/;
	push @{$m->{headers}}, $h;
	push @{$m->{header}->{lc $n}}, $h;
}

sub replace_header
{
	my ($m, $h, $l, $c) = @_;
	$h = header_format($h, $l, $c);
	my ($n) = $h =~ /^([^:]+):/;
	my $seen = 0; @{$m->{headers}} = grep { defined $_ } map { /^\Q$n\E:/i ? $seen ? undef : do { ++$seen; $h } : $_ } @{$m->{headers}};
	splice @{$m->{header}->{lc $n}};
	push @{$m->{header}->{lc $n}}, $h;
}

sub delete_header
{
	my ($m, $h, $r) = @_;
	return undef unless exists $m->{header};
	@{$m->{headers}} = grep { !/^$h:/i } @{$m->{headers}};
	delete $m->{header}->{$_} for grep { /^$h$/i } keys %{$m->{header}};
	if ($r && exists $m->{mime_parts}) { delete_header($_, $h, $r) for @{$m->{mime_parts}} }
	if ($r && exists $m->{mime_message}) { delete_header($m->{mime_message}, $h, $r) }
}

sub insert_part
{
	my ($m, $p, $i) = @_;
	splice @{$m->{mime_parts}}, $i || 0, 0, $p;
}

sub append_part
{
	my ($m, $p) = @_;
	push @{$m->{mime_parts}}, $p;
}

sub replace_part
{
	my ($m, $p, $i) = @_;
	splice @{$m->{mime_parts}}, $i, 1, $p;
}

sub delete_part
{
	my ($m, $i) = @_;
	splice @{$m->{mime_parts}}, $i, 1;
}

sub header
{
	my ($m, $h) = @_;
	return () unless exists $m->{header} && exists $m->{header}->{lc $h};
	return map { s/\n\s+/ /g; header_display($_) =~ /^$h:\s*(.*)\s*$/i; $1 } @{$m->{header}->{lc $h}};
}

sub headers
{
	my $m = shift;
	return () unless exists $m->{headers};
	return map { s/\n\s+/ /g; header_display($_) =~ /^([\w-]+:.*)\s*$/; $1 } @{$m->{headers}};
}

sub header_names
{
	my $m = shift;
	return () unless exists $m->{header};
	return keys %{$m->{header}};
}

my $encword = qr/=\?([^*?]+)(?:\*\w+)?\?(q|b)\?([^? ]+)\?=/i; # encoded words to display
sub header_display # rfc2047, rfc2231
{
	use Encode ();
	return join '',
		map { tr/ \t/ /s; $_ } # finally, squeeze multiple whitespace
		map { tr/\x00-\x08\x0b-\x1f\x7f//d; $_ } # strip control characters
		map { s/$encword/(defined Encode::find_encoding($1)) ? Encode::decode($1, (lc $2 eq 'q') ? decode_quoted_printable($3, 1) : decode_base64($3)) : $&/ieg; $_ } # decode encoded words if possible
		map { s/($encword)\s+($encword)/$1$5/g while /$encword\s+$encword/; $_ } # strip space between encoded words that we're about to decode
		map { s/\((?:\\[^\r\n]|[^\\()])*\)//g unless /^".*"$/; $_ } # strip (comments) outside "quoted strings"
		split /("(?:\\[^\r\n]|[^\\"])*")/, shift; # split on "quoted strings"
}

sub charsetof
{
	my $s = shift;
	return 'us-ascii' if !defined $s || $s =~ /^[\x00-\x7f]*$/;
	#return 'utf-8' if $s =~ /^(?:[\x00-\x7f]|[\xc2-\xdf][\x80-\xbf]|[\xe0-\xef][\x80-\xbf]{2}|[\xf0-\xf4][\x80-\xbf]{3})+$/; # This won't work until perl v5.38
	return 'utf-8' if defined eval { Encode::decode 'UTF-8', $s, Encode::FB_CROAK };
	return (defined $ENV{LANG} && $ENV{LANG} =~ /^.+\.(.+)$/) && $1 ne 'UTF-8' ? lc $1 : 'iso-8859-1'; # Make something up
}

sub header_format # rfc2822, rfc2047
{
	my ($h, $l, $c) = @_;
	$h =~ s/^\s+//, $h =~ s/\s+$//, $h =~ tr/ \t\n\r/ /s;
	use Encode (); $h = Encode::encode('UTF-8', $h) if grep { ord > 255 } split //, $h;
	$h = join ' ', map { /^".*"$/ ? $_ : !tr/\x80-\xff// ? $_ : tr/a-zA-Z0-9!*\/+-//c > length >> 1 ? join(' ', map { '=?' . ($c || charsetof($h)) . ($l ? "*$l" : '') . '?b?' . substr(encode_base64($_), 0, -1) . '?=' } (split /\n/, (s/([^\r\n]{38})/$1\n/g, $_))) : join(' ', map { '=?' . ($c || charsetof($h)) . ($l ? "*$l" : '') . '?q?' . substr(encode_quoted_printable($_, 1), 0, -1) . '?=' } (split /\n/, (s/([^\r\n]{17})/$1\n/g, $_))) } map { /^[^\s"]*".*"[^\s"]*$/ ? $_ : split / / } split /(\S*"(?:\\[^\r\n]|[^\\"])*"\S*)/, $h;
	my ($f, $p, $lf) = ('', 0); $lf = length $f, $f .= ($lf && $lf + ($lf ? 1 : 0) + length($_) - $p > 78) ? ($p = $lf, "\n") : '', $f .= $f ? ' ' : '', $f .= $_ for map { /^\S*".*"\S*$/ ? $_ : grep { length } split / / } split /(\S*"(?:\\[^\r\n]|[^\\"\r\n])*"\S*)/, $h; # fold
	return $f . "\n";
}

sub param # rfc2231, rfc2045
{
	my ($m, $h, $p) = @_;
	my @p; my $decode = 0;

	for (header($m, $h))
	{
		while (/(\b\Q$p\E(?:\*|\*\d\*?)?)=("(?:\\[^\n]|[^"\n])*"|[^\x00-\x20()<>@,;:\\"\/\[\]?=]+)/ig)
		{
			my ($n, $v) = ($1, $2);
			$v =~ s/^"//, $v =~ s/"$//, $v =~ s/\\(.)/$1/g if $v =~ /^".*"$/;
			$v =~ s/^(?:us-ascii|utf-8|iso-8859-\d{1,2})'\w+'//i and $decode = 1;
			$v =~ s/%([\da-fA-f]{2})/chr hex $1/eg if $decode && substr($n, -1) eq '*';
			push @p, [lc $n, $v];
		}
	}

	return join '', map { $_->[1] } sort { my ($ad) = $a->[0] =~ /(\d+)/; my ($bd) = $b->[0] =~ /(\d+)/; $ad <=> $bd } @p;
}

sub mimetype # rfc2045, rfc2046
{
	my ($m, $p) = @_;
	my ($e) = header($m, 'content-transfer-encoding');
	return 'application/octet-stream' if defined $e && $e !~ /^(?:[78]bit|binary|quoted-printable|base64)$/i;
	my ($type) = header($m, 'content-type');
	return lc $1 if defined $type && $type =~ /^((?:text|image|audio|video|application|message|multipart)\/[^\s;]+)/i;
	return 'message/rfc822' if !defined $type && defined $p && exists $p->{mime_type} && $p->{mime_type} =~ /^multipart\/digest/i;
	return 'text/plain';
}

sub encoding # rfc2045
{
	my $m = shift;
	my ($e) = header($m, 'content-transfer-encoding');
	return (defined $e && $e =~ /^([78]bit|binary|quoted-printable|base64)$/i) ? lc $1 : (exists $m->{body} && $m->{body} =~ tr/\x80-\xff//) ? '8bit' : '7bit';
}

my $filename_counter;
sub filename # rfc2183, rfc2045?
{
	my $p = shift;
	my $fn = param($p, 'content-disposition', 'filename') || param($p, 'content-type', 'name') || 'attachment' . ++$filename_counter;
	$fn =~ s/^.*[\\\/]//, $fn =~ tr/\x00-\x1f !"#\$%&'()*\/:;<=>?@[\\]^`{|}~\x7f/_/s;
	return $fn;
}

sub body
{
	my $m = shift;
	return exists $m->{body} ? decode($m->{body}, encoding($m)) : undef;
}

sub message
{
	my $m = shift;
	return exists $m->{mime_message} ? $m->{mime_message} : undef;
}

sub parts
{
	my ($m, $p) = @_;
	return exists $m->{mime_parts} ? [@{$m->{mime_parts}}] : [] unless defined $p;
	$m->{mime_parts} = [@{$p}];
}

sub newparam # rfc2231, rfc2045
{
	my ($n, $v, $l, $c) = (@_, '', '');
	my $high = $v =~ tr/\x80-\xff//;
	my $ctrl = $v =~ tr/\x00-\x06\x0e-\x1f\x7f//;
	my $enc = $high || $ctrl ? '*' : '';
	$c = charsetof($v) if $enc && !$c;
	$l = 'en' if $c && !$l;
	$v = "$c'$l'$v" if $enc;
	my @p; push @p, $_ while $_ = substr $v, 0, 40, '';
	s/([\x00-\x20\x7f-\xff])/sprintf '%%%02X', ord $1/eg for grep { tr/\x00-\x06\x0e-\x1f\x7f-\xff// } @p;
	s/"/\\"/g, s/^/"/g, s/$/"/g for grep { tr/\x00-\x06\x0e-\x1f\x7f ()<>@,;:\\"\/[]?=// } @p;
	return "; $n$enc=$p[0]" if @p == 1;
	return join '', map { "; $n*$_$enc=$p[$_]" } 0..$#p;
}

my $messageid_counter;
sub newmail # rfc2822, rfc2045, rfc2046, rfc2183 (also rfc3282, rfc3066, rfc2424, rfc2557, rfc2110, rfc3297, rfc2912, rfc2533, rfc1864)
{
	my @a = @_; my %a = @_; my $m = {};
	sub rfc822date { use POSIX; return strftime '%a, %d %b %Y %H:%M:%S +0000', gmtime shift; }
	my $type = $a{type} || (exists $a{parts} ? 'multipart/mixed' : exists $a{message} ? 'message/rfc822' : 'text/plain');
	my $multi = $type =~ /^multipart\//i;
	my $msg = $type =~ /^message\/rfc822$/i;
	if (exists $a{filename} && !exists $a{body} && !exists $a{message} && !exists $a{parts} && -r $a{filename} && stat($a{filename}) && open my $fh, '<', $a{filename})
	{
		$a{body} = do { local $/; my $b = <$fh>; close $fh; $b };
		$a{created} = (exists $a{created}) ? $a{created} : rfc822date((stat _)[9]);
		$a{modified} = (exists $a{modified}) ? $a{modified} : rfc822date((stat _)[9]);
		$a{read} = (exists $a{read}) ? $a{read} : rfc822date((stat _)[8]);
		$a{size} = (stat _)[7];
	}
	($a{filename}) = $a{filename} =~ /([^\\\/]+)$/ if $a{filename};
	my $bound = $multi ? join '', map { substr $bchar, int(rand(length $bchar)), 1 } 0..30 : '';
	my $disp = $a{disposition} || ($type =~ /^(?:text\/|message\/rfc822)/i ? 'inline' : 'attachment');
	my $char = $a{charset} || charsetof($a{body});
	my $enc = $a{encoding} || ($multi || $msg ? '7bit' : $a{body} ? choose_encoding($a{body}) : '7bit');
	append_header($m, $a[$_] . ': ' . $a[$_ + 1]) for grep { $_ % 2 == 0 && $a[$_] =~ /^[A-Z]/ } 0..$#a;
	append_header($m, 'Date: ' . rfc822date(time)) if grep { /^(?:date|from|sender|reply-to)$/i } keys %a and !grep { /^date$/i } keys %a;
	append_header($m, 'MIME-Version: 1.0') if grep { /^(?:date|from|sender|reply-to)$/i } keys %a and !grep { /^mime-version$/ } keys %a;
	use Sys::Hostname; append_header($m, "Message-ID: <@{[time]}.$$.@{[++$messageid_counter]}\@@{[hostname]}>") if grep { /^(?:date|from|sender|reply-to)$/i } keys %a and !grep { /^message-id$/i } keys %a;
	append_header($m, "Content-Type: $type" . ($bound ? newparam('boundary', $bound) : '') . ($char =~ /^us-ascii$/i ? '' : newparam('charset', $char))) unless $type =~ /^text\/plain$/i && $char =~ /^us-ascii$/i;
	append_header($m, "Content-Transfer-Encoding: $enc") unless $enc =~ /^7bit$/i;
	append_header($m, "Content-Disposition: $disp" . ($a{filename} ? newparam('filename', $a{filename}) : '') . ($a{size} ? newparam('size', $a{size}) : '') . ($a{created} ? newparam('creation-date', $a{created}) : '') . ($a{modified} ? newparam('modification-date', $a{modified}) : '') . ($a{read} ? newparam('read-date', $a{read}) : '')) if $a{filename} || $a{size} || $a{created} || $a{modified} || $a{read};
	append_header($m, "Content-@{[ucfirst $_]}: $a{$_}") for grep { $a{$_} } qw(description language duration location base features alternative);
	append_header($m, "Content-@{[uc $_]}: $a{$_}") for grep { $a{$_} } qw(id md5);
	($m->{mime_type}, $m->{mime_boundary}, $m->{mime_parts}) = ($type =~ /^\s*([\w\/.-]+)/, $bound, $a{parts} || []) if $multi;
	($m->{mime_type}, $m->{mime_message}) = ($type =~ /^\s*([\w\/.-]+)/, $a{message} || {}) if $msg;
	$m->{body} = encode($a{body} || '', $enc) unless $multi || $msg;
	$m->{mbox} = $a{mbox} if exists $a{mbox} && defined $a{mbox} && length $a{mbox};
	return $m;
}

sub decode
{
	my ($d, $e) = @_;
	return $e =~ /^base64$/i ? decode_base64($d) : $e =~ /^quoted-printable$/i ? decode_quoted_printable($d) : substr($d, 0, -1);
}

sub encode
{
	my ($d, $e) = @_;
	return $e =~ /^base64$/i ? encode_base64($d) : $e =~ /^quoted-printable$/i ? encode_quoted_printable($d) : $d . "\n";
}

sub choose_encoding # rfc2822, rfc2045
{
	my $len = length $_[0];
	my $high = $_[0] =~ tr/\x80-\xff//;
	my $ctrl = $_[0] =~ tr/\x00-\x06\x0e-\x1f\x7f//;
	my ($maxlen, $pos, $next) = (0, 0, 0);

	for (; ($next = index($_[0], "\n", $pos)) != -1; $pos = $next + 1)
	{
		$maxlen = $next - $pos if $next - $pos > $maxlen;
	}

	$maxlen = $len - $pos if $len - $pos > $maxlen;
	return $ctrl ? 'base64' : $high ? $len > 1024 && $high > $len * 0.167 ? 'base64' : 'quoted-printable' : $maxlen > 998 ? 'quoted-printable' : '7bit';
}

sub encode_base64 # MIME::Base64 (Gisle Aas)
{
	pos $_[0] = 0; # Note: Text must be in canonical form (i.e. with "\r\n")
	my $padlen = (3 - length($_[0]) % 3) % 3;
	my $encoded = join '', map { pack('u', $_) =~ /^.(\S*)/ } $_[0] =~ /(.{1,45})/gs;
	$encoded =~ tr{` -_}{AA-Za-z0-9+/};
	$encoded =~ s/.{$padlen}$/'=' x $padlen/e if $padlen;
	$encoded =~ s/(.{1,76})/$1\n/g;
	return $encoded;
}

sub decode_base64 # MIME::Base64 (Gisle Aas)
{
	my $data = shift;
	$data =~ tr{A-Za-z0-9+=/}{}cd;
	$data =~ s/=+$//;
	$data =~ tr{A-Za-z0-9+/}{ -_};
	return join '', map { unpack('u', chr(32 + length($_) * 3 / 4) . $_) } $data =~ /(.{1,60})/gs;
}

sub encode_quoted_printable
{
	my $quoted = shift;
	my $qcode = shift;
	my $binary = ($quoted =~ tr/\x00-\x06\x0e-\x1f\x7f//) ? '' : '\r\n';
	$quoted =~ s/([^!-<>-~ \t$binary])/sprintf '=%02X', ord $1/eg;
	$quoted =~ s/([?_])/sprintf '=%02X', ord $1/eg if $qcode;
	$quoted =~ s/((?:[^\r\n]{73,75})(?=[=])|(?:[^\r\n]{75}(?=[ \t]))|(?:[^\r\n]{75})(?=[^\r\n]{2})|(?:[^\r\n]{75})(?=[^\r\n]$))/$1=\n/g;
	$quoted =~ s/([ \t])$/sprintf '=%02X', ord $1/emg;
	# Python and mutt both behave as though this is wrong
	#$quoted .= "=\n" unless $quoted =~ /\n$/;
	$quoted .= "\n";
	return $quoted;
}

sub decode_quoted_printable
{
	my $quoted = shift;
	my $qcode = shift;
	$quoted =~ tr/\x00-\x08\x0b-\x0c\x0e-\x1f\x7f-\xff//d;
	$quoted =~ s/=\n//g;
	$quoted =~ s/_/ /g if $qcode;
	$quoted =~ s/=([0-9A-Fa-f]{2})/chr hex $1/eg;
	return $quoted;
}

my %mimetype =
(
	txt => 'text/plain', csv => 'text/csv', htm => 'text/html', html => 'text/html', vcf => 'text/vcard', ics => 'text/calendar',
	gif => 'image/gif', jpg => 'image/jpeg', jpeg => 'image/jpeg', jpe => 'image/jpeg', png => 'image/png', bmp => 'image/bmp', tiff => 'image/tiff', tif => 'image/tiff', jp2 => 'image/jp2', jpf => 'image/jpx', jpm => 'image/jpm',
	mp2 => 'audio/mpeg', mp3 => 'audio/mpeg', au => 'audio/au', aif => 'audio/x-aiff', wav => 'audio/wav',
	mpeg => 'video/mpeg', mpg => 'video/mpeg', mpe => 'video/mpeg', qt => 'video/quicktime', mov => 'video/quicktime', avi => 'video/x-msvideo', mj2 => 'video/mj2',
	rtf => 'application/rtf', wri => 'application/vnd.ms-word', pdf => 'application/pdf', ps => 'application/ps', eps => 'application/ps', zip => 'application/zip', other => 'application/octet-stream',
	doc => 'application/msword',
	dot => 'application/msword',
	docx => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
	dotx => 'application/vnd.openxmlformats-officedocument.wordprocessingml.template',
	docm => 'application/vnd.ms-word.document.macroEnabled.12',
	dotm => 'application/vnd.ms-word.template.macroEnabled.12',
	xls => 'application/vnd.ms-excel',
	xlt => 'application/vnd.ms-excel',
	xla => 'application/vnd.ms-excel',
	xlsx => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
	xltx => 'application/vnd.openxmlformats-officedocument.spreadsheetml.template',
	xlsm => 'application/vnd.ms-excel.sheet.macroEnabled.12',
	xltm => 'application/vnd.ms-excel.template.macroEnabled.12',
	xlam => 'application/vnd.ms-excel.addin.macroEnabled.12',
	xlsb => 'application/vnd.ms-excel.sheet.binary.macroEnabled.12',
	ppt => 'application/vnd.ms-powerpoint',
	pot => 'application/vnd.ms-powerpoint',
	pps => 'application/vnd.ms-powerpoint',
	ppa => 'application/vnd.ms-powerpoint',
	pptx => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
	potx => 'application/vnd.openxmlformats-officedocument.presentationml.template',
	ppsx => 'application/vnd.openxmlformats-officedocument.presentationml.slideshow',
	ppam => 'application/vnd.ms-powerpoint.addin.macroEnabled.12',
	pptm => 'application/vnd.ms-powerpoint.presentation.macroEnabled.12',
	potm => 'application/vnd.ms-powerpoint.template.macroEnabled.12',
	ppsm => 'application/vnd.ms-powerpoint.slideshow.macroEnabled.12'
);

my $add_mimetypes;
sub add_mimetypes
{
	return if $add_mimetypes++;
	open my $fh, '<', '/etc/mime.types' or return;

	while (<$fh>)
	{
		s/#.*$//, s/^\s+//, s/\s+$//; next unless $_;
		my ($mimetype, $ext) = /^(\S+)\s+(.*)$/; next unless $ext;
		$mimetype{$_} = $mimetype for split /\s+/, $ext;
	}

	close $fh;
}

sub tnef2mime
{
	my $m = shift;
	return $m unless exists $m->{mime_type} && $m->{mime_type} =~ /^multipart\//i && exists $m->{mime_parts};
	add_mimetypes();
	@{$m->{mime_parts}} = grep { defined $_ } map { (mimetype($_) =~ /^application\/ms-tnef/i && filename($_) =~ /winmail\.dat$/i) ? winmail($_) : $_ } @{$m->{mime_parts}};
	return $m;
}

sub MESSAGE { 1 }
sub ATTACHMENT { 2 }
sub MESSAGE_CLASS { 0x00078008 }
sub ATTACH_ATTACHMENT { 0x00069005 }
sub ATTACH_DATA { 0x0006800f }
sub ATTACH_FILENAME { 0x00018010 }
sub ATTACH_RENDDATA { 0x00069002 }
sub ATTACH_MODIFIED { 0x00038013 }
my $data; my @attachment; my $attachment; my $pos; my $badtnef;

sub winmail
{
	sub read_message_attribute
	{
		my $type = unpack 'C', substr $data, $pos, 1;
		return 0 unless defined $type && $type == MESSAGE; ++$pos;
		my $id = unpack 'V', substr $data, $pos, 4; $pos += 4;
		my $len = unpack 'V', substr $data, $pos, 4; $pos += 4;
		++$badtnef, return 0 if $pos + $len > length $data;
		my $buf = substr $data, $pos, $len; $pos += $len;
		my $chk = unpack 'v', substr $data, $pos, 2; $pos += 2;
		my $tot = unpack '%16C*', $buf;
		++$badtnef unless $chk == $tot;
		return $chk == $tot;
	}

	sub read_attribute_message_class
	{
		my $type = unpack 'C', substr $data, $pos, 1;
		return unless defined $type && $type == MESSAGE;
		my $id = unpack 'V', substr $data, $pos + 1, 4;
		return unless $id == MESSAGE_CLASS; $pos += 5;
		my $len = unpack 'V', substr $data, $pos, 4; $pos += 4;
		++$badtnef, return if $pos + $len > length $data;
		my $buf = substr $data, $pos, $len; $pos += $len;
		my $chk = unpack 'v', substr $data, $pos, 2; $pos += 2;
		my $tot = unpack '%16C*', $buf;
		++$badtnef unless $chk == $tot;
	}

	sub read_attachment_attribute
	{
		my $type = unpack 'C', substr $data, $pos, 1;
		return 0 unless defined $type && $type == ATTACHMENT; ++$pos;
		my $id = unpack 'V', substr $data, $pos, 4; $pos += 4;
		++$badtnef if $id == ATTACH_RENDDATA && @attachment && !exists $attachment->{body};
		push @attachment, $attachment = {} if $id == ATTACH_RENDDATA;
		my $len = unpack 'V', substr $data, $pos, 4; $pos += 4;
		++$badtnef, return 0 if $pos + $len > length $data;
		my $buf = substr $data, $pos, $len; $pos += $len;
		my $chk = unpack 'v', substr $data, $pos, 2; $pos += 2;
		my $tot = unpack '%16C*', $buf;
		++$badtnef, return 0 unless $chk == $tot;
		$attachment->{body} = $buf, $attachment->{size} = length $buf if $id == ATTACH_DATA;
		$buf =~ s/\x00+$//, $attachment->{filename} = $buf, $attachment->{type} = $mimetype{($attachment->{filename} =~ /\.([^.]+)$/) || 'other'} || 'application/octet-stream' if $id == ATTACH_FILENAME && !exists $attachment->{filename};
		my $fname; $attachment->{filename} = $fname, $attachment->{type} = $mimetype{($attachment->{filename} =~ /\.([^.]+)$/) || 'other'} || 'application/octet-stream' if $id == ATTACH_ATTACHMENT && ($fname = realname($buf));
		use POSIX; sub word { unpack 'v', substr($_[0], $_[1] * 2, 2) }
		$attachment->{modified} = strftime '%a, %d %b %Y %H:%M:%S +0000', gmtime mktime word($buf, 5), word($buf, 4), word($buf, 3), word($buf, 2), word($buf, 1) - 1, word($buf, 0) - 1900 if $id == ATTACH_MODIFIED;
		return 1;
	}

	sub realname
	{
		my $buf = shift;
		my $pos = index $buf, "\x1e\x00\x01\x30\x01"; return unless $pos >= 0; $pos += 8;
		my $len = unpack 'V', substr($buf, $pos, 4); $pos += 4;
		my $name = substr($buf, $pos, $len) or return;
		$name =~ s/\x00+$//;
		return $name;
	}

	my $m = shift;
	add_mimetypes();
	$pos = 0; $data = body($m); @attachment = (); $badtnef = 0;
	my $signature = unpack 'V', substr($data, $pos, 4); $pos += 4;
	return $m unless $signature == 0x223E9F78;
	my $key = unpack 'v', substr($data, $pos, 2); $pos += 2;
	my $type = unpack 'C', substr($data, $pos, 1);
	return $m unless $type == MESSAGE || $type == ATTACHMENT;
	do {} while read_message_attribute();
	read_attribute_message_class();
	do {} while read_message_attribute();
	do {} while read_attachment_attribute();
	++$badtnef if @attachment && !exists $attachment->{body};
	return ($badtnef) ? $m : map { newmail(%{$_}) } @attachment;
}

1;

# vi:set ts=4 sw=4:
