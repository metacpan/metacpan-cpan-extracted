# Mail::MboxParser - object-oriented access to UNIX-mailboxes
# Body.pm		   - the (textual) body of an email
#
# Copyright (C) 2001  Tassilo v. Parseval
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# Version: $Id: Body.pm,v 1.14 2002/02/21 09:06:14 parkerpine Exp $

package Mail::MboxParser::Mail::Body;

require 5.004;

use Carp;

use strict;
use base qw(Exporter);
use vars qw($VERSION @EXPORT @ISA $AUTOLOAD $_HAVE_NOT_URI_FIND);
$VERSION 	= "0.15";
@EXPORT  	= qw();
@ISA	 	= qw(Mail::MboxParser::Base Mail::MboxParser::Mail);

use overload '""' => sub { shift->as_string }, fallback => 1;

BEGIN { 
    eval { require URI::Find; };
    if ($@) { 
	$_HAVE_NOT_URI_FIND = 1;
    }
}

sub init(@) {
    my ($self, $ent, $bound, $conf) = @_;
    $self->{CONTENT}	= $ent->body; 
    $self->{BOUNDARY}	= $bound;	     # the one in Content-type
    $self->{ARGS}	= $conf;

    $self->{ARGS}->{decode} ||= 'NEVER';

    $self->_make_decoder($ent->head->mime_encoding) 
	if $self->{ARGS}->{decode} =~ /BODY|ALL/;;
    $self;
}

sub _make_decoder {
    my ($self, $enc) = @_;
    if ($enc eq 'base64') {
	require MIME::Base64;
	return $self->{DECODER} = sub { MIME::Base64::decode_base64(shift) };
    } 
    if ($enc eq 'quoted-printable') {
	require MIME::QuotedPrint;
	return $self->{DECODER} = sub { MIME::QuotedPrint::decode_qp(shift) };
    }
    $self->{DECODER} = sub { $_[0] };
} 

sub as_string {	
    my ($self, %args) = @_;
    $self->reset_last;
    return join "", $self->as_lines(strip_sig => 1) if $args{strip_sig};
    my $decode = $self->{ARGS}->{decode};
    if ($decode eq 'BODY' || $decode eq 'ALL') {
	return join "", map { $self->{DECODER}->($_) } @{$self->{CONTENT}};
    }
    return join "", @{$self->{CONTENT}};
}
	

sub as_lines() { 
    my ($self, %args) = @_;
    $self->reset_last;
    my $decode = $self->{ARGS}->{decode};
    if ($decode eq 'BODY' || $decode eq 'ALL') {
	return map { $self->{DECODER}->($_) } @{$self->{CONTENT}};
    }

    return @{$self->{CONTENT}} if ! $args{strip_sig};

    my @lines;
    for (@{ $self->{CONTENT} }) {
	last if /^--\040?[\r\n]?$/;
	push @lines, $_;
    }
    return @lines;
}
					   
	
sub signature() {
    my $self = shift;
    $self->reset_last;
    my $decode = $self->{ARGS}->{decode};
    my $bound = $self->{BOUNDARY};

    my @signature;
    my $seperator = 0;
    for (@{$self->{CONTENT}}) {

	# we are still outside the signature
	if (! /^--\040?[\r\n]?$/ && not $seperator) {
	    next;
	}

	# we hit the signature delimiter (--)
	elsif (not $seperator) { $seperator = 1; next }

	chomp;	

	# we are inside signature: is line perhaps MIME-boundary?
	last if $bound && /^--\Q$bound\E/ && $seperator;

	# none of the above => signature line
	push @signature, $_; 
    }
	
    $self->{LAST_ERR} = "No signature found" if !@signature;
    if ($decode eq 'BODY' || $decode eq 'ALL') {
	$_ = $self->{DECODER}->($_) for @signature;
    }
    return @signature if $seperator;
    return ();
}

sub extract_urls(@) {
    my ($self, %args) = @_;
    $self->reset_last;

    $args{unique} = 0 if not exists $args{unique};

    if ($_HAVE_NOT_URI_FIND) {
	carp <<EOW;
You need the URI::Find module in order to use extract_urls.
EOW
	return;
    }
    else { 
	my @uris; my %seen;

	for my $line (@{$self->{CONTENT}}) {
	    chomp $line;
	    URI::Find::find_uris($line, sub {
		    my (undef, $url) = @_;
		    $line =~ s/^\s+|\s+$//;
		    if (not $seen{$url}) {
			push @uris, { url => $url, context => $line };
		    }
		    $seen{$url}++ if $args{unique};
		}
	    );
	}
	$self->{LAST_ERR} = "No URLs found" if @uris == 0;

	return @uris;
    }
}

sub quotes() {
    my $self = shift;
    my $decode = $self->{ARGS}->{decode};
    $self->reset_last;

    my %ret;
    my $q 		= 0; # num of '>'
    my $in 		= 0; # being inside a quote
    my $last 	= 0; # num of quotes in last line

    for (@{$self->{CONTENT}}) {

	if ($decode eq 'ALL' || $decode eq 'BODY') {
	    $_ = $self->{DECODER}->($_);
	}
        
	# count quotation signs
	$q = 0;
	my $t = "a" x length;
	for my $c (unpack $t, $_) {
	    if ($c eq '>') 		{ $q++ }
	    if ($c ne '>' && $c ne ' ') { last }
	}

	# first: create a hash-element for level $q
	if (! exists $ret{$q}) {
	    $ret{$q} = [];
	}

	# if last line had the same level as current one:
	# attach the line to the last one
	if ($last == $q) {
	    if (@{$ret{$q}} == 0)   { $ret{$q}->[$q] .= $_ }
	    else		    { $ret{$q}->[-1] .= $_ }
	}
	# if not:
	# create a new array-element in the appropriate hash-element
	else { 
	    push @{$ret{$q}}, $_;
	}
	$last = $q;
    }
    return \%ret;
}


1;

__END__

=head1 NAME

Mail::MboxParser::Mail::Body - rudimentary mail-body object

=head1 SYNOPSIS

    use Mail::MboxParser;

    [...]

    # $msg is a Mail::MboxParser::Mail
    my $body = $msg->body(0);

    # or preferably

    my $body = $msg->body($msg->find_body);

    for my $line ($body->signature) { print $line, "\n" }
    for my $url ($body->extract_urls(unique => 1)) {
        print $url->{url}, "\n";
        print $url->{context}, "\n";
    }
        
=head1 DESCRIPTION

This class represents the body of an email-message.  Since emails can have
multiple MIME-parts and each of these parts has a body it is not always easy to
say which part actually holds the text of the message (if there is any at all).
Mail::MboxParser::Mail::find_body will help and suggest a part.

=head1 METHODS

=over 4

=item B<as_string ([strip_sig =E<gt> 1])>

Returns the textual representation of the body as one string. Decoding takes
place when the mailbox has been opened using the decode => 'BODY' | 'ALL'
option.

If 'strip_sig' is set to a true value, the signature is stripped from the
string.

=item B<as_lines ([strip_sig =E<gt> 1])>

Sames as as_string() just that you get an array of lines with newlines attached
to each line.

B<NOTE:> When the body is actually some encoded binary data (most commonly such
a body is base64-encoded), you can still use this method. Then you wont really
get proper lines. Instead you get chunks of binary data that you should
concatenate as in

    my $binary = join "", $body->as_lines;

If 'strip_sig' is set to a true value, the signature is stripped from the
string.

=item B<signature>

Returns the signature of a message as an array of lines. Trailing newlines are
already removed.

$body->error returns a string if no signature has been found.

=item B<extract_urls>

=item B<extract_urls (unique =E<gt> 1)>

Returns an array of hash-refs. Each hash-ref has two fields: 'url' and
'context' where context is the line in which the 'url' appeared.

When calling it like $mail->extract_urls(unique => 1), duplicate URLs will be
filtered out regardless of the 'context'. That's useful if you just want a list
of all URLs that can be found in your mails.

$body->error() will return a string if no URLs could be found within the body.

=item B<quotes>

Returns a hash-ref of array-refs where the hash-keys are the several levels of
quotation. Each array-element contains the paragraphs of this quotation-level
as one string. Example:

	my $quotes = $msg->body($msg->find_body)->quotes;
	print $quotes->{1}->[0], "\n";
	print $quotes->{0}->[0], "\n";

This should print the first paragraph of the mail-body that has been quoted
once and below that the paragraph that supposedly is the reply to this
paragraph. Perhaps thus:

	> I had been trying to work with the CGI module 
	> but I didn't yet fully understand it.

	Ah, it is tricky. Have you read the CGI-FAQ that 
	comes with the module?

Mark that empty lines will not be ignored and are part of the lines contained
in the array of $quotes->{0}.

So below is a little code-snippet that should, in most cases, restore the first
5 paragraphs (containing quote-level 0 and 1) of an email:

	for (0 .. 4) {
		print $quotes->{0}->[$_];
		print $quotes->{1}->[$_];
	}

Since quotes() considers an empty line between two quotes paragraphs as a
paragraph in $quotes->{0}, the paragraphs with one quote and those with zero
are balanced. That means: 

scalar @{$quotes->{0}} - DIFF == scalar @{$quotes->{1}} where DIFF is element
of {-1, 0, 1}.

Unfortunately, quotes() can up to now only deal with '>' as quotation-marks.

=back

=head1 VERSION

This is version 0.55.

=head1 AUTHOR AND COPYRIGHT

Tassilo von Parseval <tassilo.von.parseval@rwth-aachen.de>

Copyright (c)  2001-2005 Tassilo von Parseval.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
