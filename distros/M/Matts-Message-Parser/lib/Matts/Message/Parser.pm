
package Matts::Message::Parser;
use strict;
use vars qw(@Try_Encodings $VERSION);

$VERSION = '1.0';

# MIME Message parser, for email and nntp engines.

use Matts::Message;
use MIME::Base64;
use MIME::QuotedPrint;
use Carp;
use UNIVERSAL;

@Try_Encodings = qw(euc-cn euc-jp shiftjis euc-kr big5-eten iso-8859-15 );

sub debug {
    return unless $ENV{DEBUG};
    warn((caller)[2], @_);
}

sub mkbinmode {
    if ($] > 5.007) {
        binmode($_[0], ':utf8');
    }
    else {
        binmode($_[0]);
    }
}

=head1 NAME

Matts::Message::Parser - a MIME message parser for email and nttp

=head1 SYNOPSIS

  use Matts::Message::Parser;
  open(my $fh, "foo.eml");
  my $msg = Matts::Message::Parser->parse($fh);

=head1 DESCRIPTION

This is an email parser I originally wrote when I ran my own business that tries
quite hard to decode the various parts of an email correctly and down to unicode
so that all strings can be treated the same in perl.

DO NOT USE THIS MODULE

I urge you, please don't. It's not a very good API. I'm just uploading it to
CPAN because it's better for my purposes than most of the Email::* and Mail::*
classes I can find, and it's fast, and doesn't use any memory when parsing very
large emails, which is a huge bonus for me. But I have no intention of documenting
this module any more than I have to.

=head1 AUTHOR

Matt Sergeant, <matt@sergeant.org>

=head1 LICENSE

This is free software. You may use it and redistribute it under the same terms
as perl itself.

=head1 HACKING NOTES

=head2 This is how mail messages can come in:

=over 4

=item 1. Plain text

Plain text messages come in with a content-type of text/plain. They
may contain attachments as UU Encoded strings.

=item 2. HTML text

Straight HTML messages come in with a content-type of text/html. They
may not contain attachments as far as I'm aware.

=item 3. Mixed text, html and maybe other.

These messages come in as MIME messages with the content-type of
multipart/alternative (alternate means you get to pick which view of the
message to display, as all must contain the same basic information).

There may not be attachments this way as far as I'm aware.

=item 4. Plain text with attachments

Here the content-type is multipart/mixed. The first part of the multipart
message is the the plain text message (after the preamble, that is), with
a content type of text/plain. The remaining parts are attachments.

=item 5. HTML text with attachments

Again, the content-type is multipart/mixed. The first part of the multipart
message is the html message, with a content-type of text/html. The
remaining parts are attachments.

=item 6. Mixed text, html with attachments

Here the main part of the message has a content-type of multipart/mixed. The
first part has a content-type of multipart/alternative, and is identical to
item 3 above. The remaining parts are the attachments.

=item 7. Report.

This is a delivery status report. It comes with the main part of the message
having a content-type of multipart/report, the first one or two parts of which
may be textual content of some sort, and the last seems to be of type
message/rfc822. 

=back

Overall this is a fairly naive way to view email messages, as the
attachments can be email messages themselves, and thus it gets very
recursive. But this should be enough for us to deal with right now.

=cut

# constructor
sub parse {
    my $class = shift;
    
    my $ioref;
    
    if (ref($_[0]) and UNIVERSAL::isa($_[0], 'IO::Handle')) {
        $ioref = $_[0];
    }
    else {
        eval {
            if (defined(*{$_[0]})) {
                # throw an exception if not a FH
                $ioref = *{$_[0]}{IO};
                # if no exception thrown, just use the real FH
                $ioref = $_[0] if defined($ioref);
            }
        };
    }
    
    if (!defined $ioref) {
        $ioref = $class->new_tmpfile();
        print $ioref $_[0];
        seek($ioref, 0, 0);
    }
    
    shift; # lose $_[0] now
    my %opts = @_;
    
    binmode($ioref);
    
    my $msg = Matts::Message->new();

    $msg->size((stat($ioref))[7]);
    $msg->mtime((stat($ioref))[9]);
    
    my $header = <$ioref>;
    $header =~ s/\r\n/\n/;
    # $header =~ s/\s+$//;
    
    if ($header =~ /^from\s+([^:].*)$/) {
        $msg->header('Envelope-From', $1);
        $header = <$ioref>;
        $header =~ s/\r\n/\n/;
        # $header =~ s/\s+$//;
    }
    
    local $_; # protect from abuse
    
    HEADER:
    while (my $last = <$ioref>) {
        $last =~ s/\r\n/\n/;
        # chomp($last);
        # $last =~ s/\s+$//;
        if ($last =~ /^\s+\S/) { # if its a continuation
            $header .= $last; # fold continuations
            next HEADER;
        }
        
        # not a continuation...
        my ($key, $value) = split( /:\s*/, $header, 2);
        if ($value =~ /[\x80-\xff]/) {
            # header contains high 8bit chars
            $msg->binary_header($key, $value);
        }
        else {
            $value = $class->decode_header($key, $value);
            # debug("Got header: $key: $value\n");
            $msg->header($key, $value);
        }
        
        $header = $last;
        
        last HEADER if ($last =~ /^$/m);
    }
    
    if ($opts{header_only}) {
        if ($msg->binary_headers) {
            debug("Binary headers found - trying to decode them without body hints\n");
            my $conv = $class->converter('ASCII');
            foreach my $header ($msg->binary_headers()) {
                debug("Trying to fix up $header\n");
                $msg->header($header, $conv->convert($msg->binary_header($header)));
            }
        }
        return $msg;
    }
    
    my $body = $class->new_tmpfile();
    binmode($body);
    my $lines = 0;
    
    while (my $line = <$ioref>) {
        $line =~ s/\r\n/\n/;
        print $body $line;
        $lines++;
    }
    
    seek($body, 0, 0);
    
    $class->parse_body($msg, $msg, $body);

    # warn("Fixup binary headers\n");

    return $msg unless $msg->binary_headers;

    my $binenc = '';
    my @bodies = $msg->bodies;
    my $id = 0;
    while (@bodies) {
        my ($type, $fh) = splice(@bodies, 0, 2);
        my $enc = $msg->body_enc($id);
        if ($enc ne 'null') {
            $binenc = $enc;
            last;
        }
        $id++;
    }
    
    debug("Fixup binary headers. Got binenc: $binenc\n");
    
    if (!$binenc) {
        my $ct = $msg->header('x-original-content-type');
        debug("binenc was blank. Trying content-type: $ct\n");
        if ($ct and $ct =~ /charset="?([^\";]+)"?;?/i) {
            $binenc = $1;
        }
    }
    
    $binenc ||= 'ASCII';
    
    my $conv = $class->converter($binenc);
    foreach my $header ($msg->binary_headers()) {
        debug("Fixing up $header to be $binenc\n");
        $msg->header($header,
            $conv->convert($msg->binary_header($header)));
    }
    
    unless ($msg->header('message-id')) {
        $msg->header('message-id', '<' . time . '@unknown>');
    }
    
    unless ($msg->header('subject')) {
        $msg->header('subject', "No Topic");
    }
    
    return $msg;
}

sub parse_body {
    my $class = shift;
    my ($msg, $_msg, $body) = @_;
    
    my $type = $_msg->header('Content-Type') || 'text/plain';
    
    debug("Parsing message of type: $type\n");
    
    if ($type =~ /^text\/html/i) {
        debug("Parse text/html\n");
        $class->parse_normal($msg, $_msg, $body);
    }
    elsif ($type =~ /^text/i) {
        debug("Parse text/plain\n");
        $class->parse_normal($msg, $_msg, $body);
        #$class->process_uue($msg);
    }
    elsif ($type =~ /ms-tnef/i) {
        debug("Parse ms-tnef\n");
        eval {
            $class->parse_tnef($msg, $_msg, $body);
        };
        if ($@) {
            warn("parse_tnef failed: $@\n");
        }
    }
    elsif ($type =~ /^multipart\/alternative/i) {
        debug("Parse multipart/alternative\n");
        $class->parse_multipart_alternate($msg, $_msg, $body);
    }
    elsif ($type =~ /^multipart\//i) {
        debug("Parse $type\n");
        $class->parse_multipart_mixed($msg, $_msg, $body);
    }
    else {
        debug("Regular attachment\n");
        $class->decode_attachment($msg, $_msg, $body);
    }
    
    if (!$msg->body()) {
        debug("No message body found. Reparsing\n");
        my $part_fh = $class->new_tmpfile();
        my $part_msg = Matts::Message->new();
        $class->decode_body($msg, $part_msg, $part_fh);
    }
    
    $class->process_uue($msg);
}

sub parse_multipart_alternate {
    my $class = shift;
    my ($msg, $_msg, $body) = @_;
    
    my ($boundary) = $_msg->header('content-type') =~ /boundary\s*=\s*["']?([^"';]+)["']?/i;
    
    my $preamble = '';

    debug("m/a got boundary: $boundary\n");
    
    # extract preamble (normally contains "This message is in Multipart/MIME format")
    while(my $line = <$body>) {
        $line =~ s/\r\n/\n/;
        last if $line =~ /^\-\-\Q$boundary\E$/;
        $preamble .= $line;
    }

    debug("preamble: [[$preamble]]\n");
    
    my $part_fh = $class->new_tmpfile();
    my $part_msg = Matts::Message->new();
    my $in_body = 0;
    
    my $header;

    while(<$body>) {
        s/\r\n/\n/;
        # debug($_);
        if (/^\-\-\Q$boundary\E/ || eof($body)) {
            debug("m/a got end of section\n");
            # end of part
            seek($part_fh, 0, 0);
            my $line = $_;
            # assume body part if it's text
            if ($part_msg->header('content-type') =~ /^text/i) {
                $class->decode_body($msg, $part_msg, $part_fh);
            }
            else {
                debug("Likely virus?\n");
                $class->decode_attachment($msg, $part_msg, $part_fh);
            }
            last if $line =~ /^\-\-\Q$boundary\E\-\-$/;
            $in_body = 0;
            $part_msg = Matts::Message->new();
            $part_fh = $class->new_tmpfile();
            next;
        }
        
        if ($in_body) {
            print $part_fh $_;
        }
        else {
            # chomp($_);
            s/\s+$//;
            if (m/^\S/) {
                if ($header) {
                    my ($key, $value) = split( /:\s*/, $header, 2);
                    $part_msg->header($key, $value);
                }
                $header = $_;
            }
            elsif (/^$/) {
                if ($header) {
                    my ($key, $value) = split( /:\s*/, $header, 2);
                    $part_msg->header($key, $value);
                }
                $in_body = 1;
            }
            else {
                $_ =~ s/^\s*//;
                $header .= $_;
            }
        }
    }
    
}

sub parse_multipart_mixed {
    my $class = shift;
    my ($msg, $_msg, $body) = @_;
    
    my ($boundary) = $_msg->header('content-type') =~ /boundary\s*=\s*["']?([^"';]+)["']?/i;
    
    debug("m/m Got boundary: $boundary\n");
    my $preamble = '';
    
    # extract preamble (normally contains "This message is in Multipart/MIME format")
    while(my $line = <$body>) {
        $line =~ s/\r\n/\n/;
        last if $line =~ /^\-\-\Q$boundary\E$/;
        $preamble .= $line;
    }

    debug("Extracted preamble: [[$preamble]]\n");
    
    my $part_fh = $class->new_tmpfile();
    my $part_msg = Matts::Message->new(); # just used for headers storage
    my $in_body = 0;
    
    my $header;

    while(<$body>) {
        s/\r\n/\n/;
        # debug($_);
        if (/^\-\-\Q$boundary\E/ || eof($body)) {
            # end of part
            debug("Got end of MIME section: $_\n");
            my $line = $_;
            seek($part_fh, 0, 0);
            $class->parse_body($msg, $part_msg, $part_fh);
            
            last if $line =~ /^\-\-\Q${boundary}\E\-\-$/;
            $in_body = 0;
            $part_msg = Matts::Message->new();
            $part_fh = $class->new_tmpfile();
            next;
        }
        
        if ($in_body) {
            print $part_fh $_;
        }
        else {
            # chomp($_);
            s/\s+$//;
            if (m/^\S/) {
                if ($header) {
                    my ($key, $value) = split( /:\s*/, $header, 2);
                    $part_msg->header($key, $value);
                }
                $header = $_;
            }
            elsif (/^$/) {
                if ($header) {
                    my ($key, $value) = split( /:\s*/, $header, 2);
                    $part_msg->header($key, $value);
                }
                $in_body = 1;
            }
            else {
                $_ =~ s/^\s*//;
                $header .= $_;
            }
        }
    }
    
}

sub parse_normal {
    my $class = shift;
    my ($msg, $_msg, $body) = @_;
    
    # extract body, store it in $msg
    $class->decode_body($msg, $_msg, $body);
}

use File::Path qw(rmtree);

sub parse_tnef {
    my $class = shift;
    my ($msg, $_msg, $body) = @_;
    
    my ($type, $main) = $class->decode($_msg, $body);
    debug("got tnef: $type\n");
    
    my $dir = $class->new_tmpdir();
    
    # Create a tnef object
    my $tnef = Matts::Message::TNEF->read($main, { output_dir => $dir })
        or die $Matts::Message::TNEF::errstr;

    my $body_part = $tnef->message();
    if (my $data = $body_part->data) {
        my $fh = $class->new_tmpfile();
        debug("Got tnef body part: $data\n");
        print $fh $data;
        seek($fh, 0, 0);
        # Make possibly invalid assumption that it's text/plain
        debug("Adding tnef body part\n");
        $msg->add_body_part("text/plain", $fh);
    }
    
    for my $part ($tnef->attachments) {
        my $fh = $class->new_tmpfile();
        print $fh $part->data;
        seek($fh, 0, 0);
        my $filename = $part->longname;
        debug("Got tnef attachment part $filename\n");
        debug("Adding tnef attachment: $filename\n");
        $msg->add_attachment("application/octet-stream", $fh, $filename);
    }
    
    rmtree($dir);
}

sub process_uue {
    my $class = shift;
    my ($msg) = @_;
}

sub _decode_header {
    my ($encoding, $cte, $data) = @_;
    
    my $converter = __PACKAGE__->converter($encoding);
    my $decoder = $cte eq 'B' ? \&MIME::Base64::decode_base64 :
                  $cte eq 'Q' ? \&MIME::QuotedPrint::decode_qp :
                  die "Unknown encoding type '$cte' in RFC2047 header";
    
    return $converter->convert($decoder->($data));
}

# decode according to RFC2047
sub decode_header {
    my $class = shift;
    my ($key, $header) = @_;

    return '' unless $header;
    return $header unless ($header =~ /=\?/ or $header =~ /[\x80-\xff]/);

    $header =~ s/=\?([\w_-]+)\?([bqBQ])\?(.*?)\?=/_decode_header($1, uc($2), $3)/ge;
    return $header;
}

sub decode_body {
    my $class = shift;
    my ($msg, $part_msg, $body) = @_;
    
    my ($type, $main) = $class->decode($part_msg, $body);

    debug("got body: $type\n");
    
    $msg->add_body_part($type, $main);
}

sub decode_attachment {
    my $class = shift;
    my ($msg, $part_msg, $fh) = @_;
    
    debug("decoding attachment\n");
    
    my ($type, $content, $filename) = $class->decode($part_msg, $fh);
    
    $msg->add_attachment($type, $content, $filename);
}

sub decode ($$;$) {
    my $class = shift;
    my ($msg, $body) = @_;
    
    my $fh = $class->new_tmpfile();
    binmode($fh);
    
    my $hibit;
    
    if (lc($msg->header('content-transfer-encoding')) eq 'quoted-printable') {
        debug("decoding QP file\n");
        while(<$body>) {
            $_ = MIME::QuotedPrint::decode_qp($_);
            print $fh $_;
            $hibit++ if /[\x80-\xff]/;
        }
    }
    elsif (lc($msg->header('content-transfer-encoding')) eq 'base64') {
        debug("decoding B64 file\n");
        my $output = '';
        local $/ = "\n";
        my $not_really_base64 = 0;
        while(<$body>) {
            # check to see if its really base64 encoded data
            $not_really_base64++ if /[<\.,]/;
            chomp;
            if ($not_really_base64) {
                print $fh $_;
                $hibit++ if /[\x80-\xff]/;
            }
            else {
                # pad with = chars - stops MIME::Base64 outputting warnings
                if (my $len = (length($_) % 4)) {
                    $_ .= "=" x (4 - $len);
                }
                $_ = MIME::Base64::decode_base64($_);
                print $fh $_;
                $hibit++ if /[\x80-\xff]/;
            }
        }
    }
    else {
        debug("decoding other encoding\n");
        # Encoding is one of 7bit, 8bit, binary or x-something - just save.
        my $buf;
        while($buf = <$body>) {
            # debug("BODY: $buf");
            print $fh $buf;
            $hibit++ if $buf =~ /[\x80-\xff]/;
        }
    }
    
    seek($fh, 0, 0);
    
    my $type = $msg->header('content-type');
    local $^W;
    my ($filename) = ($msg->header('content-disposition') =~ /name="?([^\";]+)"?/i);
    if (!$filename) {
        ($filename) = ($msg->header('content-type') =~ /name="?([^\";]+)"?/i);
    }
    
    debug("Body type was: $type\n");
    
    my $binenc;
    if ($type =~ /html/i) {
        while (<$fh>) {
            if (/<META\s[^>]*charset="?([\w-]*)[^>]*>/i) {
                $binenc = $1;
                $type = "text/html";
                last;
            }
        }
        seek($fh, 0, 0);
    }
    
    my $converter;
    if ($binenc) {
        $converter = $class->converter($binenc);
        $msg->header('content-type', 'text/html');
    }
    elsif ($type && ($type =~ /^text\b/i)) {
        # text type - might need to translate to UTF8
        debug("Trying to get charset from content-type: $type\n");
        # remember to strip charset portion - we can always add it later.
        $msg->header('X-Original-Content-Type', $type);
        if ($type =~ s/charset="?([^\";]+)"?;?//i) {
            $binenc = $1;
            $converter = $class->converter($binenc);
            $msg->header('content-type', $type);
        }
    }
    
    if ($hibit) {
        # we say ascii here, but in reality the converter should skip to the next converter
        $converter ||= $class->converter('ascii');
    }
    
    if ($converter) {
        my $decoded_fh = $class->new_tmpfile();
        my $data = '';
        while (<$fh>) {
            $data .= $_;
        }
        $data =~ s/<META\s[^>]*charset="?([\w-]*)[^>]*>//i;
        print $decoded_fh $converter->convert($data);
        seek($decoded_fh, 0, 0);
        # warn("Decoded body. Returning type = $type; charset=$binenc\n");
        return "$type; charset=$binenc", $decoded_fh, $filename;
    }
    
    return $type, $fh, $filename;
}

use File::Temp qw(tempfile tempdir);

sub new_tmpfile {
    my $class = shift;
    my $tmpfile = tempfile() || croak "new_tmpfile failed : $!";
    mkbinmode($tmpfile);
    return $tmpfile;
}

sub new_tmpdir {
    my $class = shift;
    return tempdir(CLEANUP => 1) || croak "new_tmpdir failed: $!";
}

sub converter {
    my $class = shift;
    my ($charset) = @_;
    
    # some broken mailers say they're us-ascii, but include higher chars
    # $charset = 'ISO-8859-15' if $charset =~ /us-?ascii/i; 

    my $converter = eval { EncodeConverter->new($charset) }
                    || NullConverter->new();

    return $converter;
}

package EncodeConverter;

*debug = *Matts::Message::Parser::debug;

my $loaded = 0;
sub load_encode {
    return if $loaded;
    require Encode;
    require Encode::Alias;
    foreach my $enc (Encode->encodings(':all')) {
        $enc =~ /^cp(\d+)$/ or next;
        # warn("Defining alias: windows-$1 => $enc\n");
        eval { Encode::Alias::define_alias("windows-$1" => $enc) };
        warn($@) if $@;
    }
    eval { Encode::Alias::define_alias("big5" => 'big5-eten') };
    eval { Encode::Alias::define_alias("iso-8859-8-i" => 'iso-8859-8') };
    warn($@) if $@;
    $loaded++;
}

sub new {
    my $class = shift;
    my ($from) = @_;
    load_encode();
    return bless { from => $from }, $class;
}

sub try_decode {
    my $self = shift;
    my $data = shift;
    foreach my $enc ($self->{from}, @Matts::Message::Parser::Try_Encodings) {
        next if $enc =~ /ascii/i;
        debug("Trying: $enc\n");
        my $d = $data;
        my $results = eval {
            Encode::decode($enc, $d, Encode::FB_CROAK());
        };
        if (!$@) {
            # debug("Success!: $enc => $results\n");
            if ($self->{from} ne $enc) {
                $self->{from} = $enc;
            }
            return wantarray ? ($results, $enc) : $results;
        }
        debug("$enc failed: $@\n");
    }
    return wantarray ? ($data, 'UTF-8') : $data;
}

sub convert {
    my $self = shift;
    return scalar $self->try_decode($_[0]);
}

package NullConverter;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub try_decode {
    my $self = shift;
    return $_[0];
}

sub convert {
    my $self = shift;
    return $_[0];
}

# Taken from Convert::TNEF.pm
#
# Copyright (c) 1999 Douglas Wilson <dougw@cpan.org>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Matts::Message::TNEF;

use strict;
use integer;
use vars qw(
  $TNEF_SIGNATURE
  $TNEF_PURE
  $LVL_MESSAGE
  $LVL_ATTACHMENT
  $errstr
  $g_file_cnt
  %dflts
  %atp
  %att
  %att_name
);

use Carp;
use File::Spec;

# Set some TNEF constants. Everything turned
# out to be in little endian order, so I just added
# 'reverse' everywhere that I needed to
# instead of reversing the hex codes.
$TNEF_SIGNATURE = reverse pack( 'H*', '223E9F78' );
$TNEF_PURE      = reverse pack( 'H*', '00010000' );

$LVL_MESSAGE    = pack( 'H*', '01' );
$LVL_ATTACHMENT = pack( 'H*', '02' );

%atp = (
  Triples => pack( 'H*', '0000' ),
  String  => pack( 'H*', '0001' ),
  Text    => pack( 'H*', '0002' ),
  Date    => pack( 'H*', '0003' ),
  Short   => pack( 'H*', '0004' ),
  Long    => pack( 'H*', '0005' ),
  Byte    => pack( 'H*', '0006' ),
  Word    => pack( 'H*', '0007' ),
  Dword   => pack( 'H*', '0008' ),
  Max     => pack( 'H*', '0009' ),
);

for ( keys %atp ) {
  $atp{$_} = reverse $atp{$_};
}

sub _ATT {
  my ( $att, $id ) = @_;
  return reverse($id) . $att;
}

# The side comments are 'MAPI' equivalents
%att = (
  Null => _ATT( pack( 'H*', '0000' ), pack( 'H4', '0000' ) ),
  # PR_ORIGINATOR_RETURN_ADDRESS
  From => _ATT( $atp{Triples}, pack( 'H*', '8000' ) ),
  # PR_SUBJECT
  Subject  => _ATT( $atp{String}, pack( 'H*', '8004' ) ),
  # PR_CLIENT_SUBMIT_TIME
  DateSent => _ATT( $atp{Date},   pack( 'H*', '8005' ) ),
  # PR_MESSAGE_DELIVERY_TIME
  DateRecd => _ATT( $atp{Date}, pack( 'H*', '8006' ) ),
  # PR_MESSAGE_FLAGS
  MessageStatus => _ATT( $atp{Byte}, pack( 'H*', '8007' ) ),
  # PR_MESSAGE_CLASS
  MessageClass => _ATT( $atp{Word}, pack( 'H*', '8008' ) ),
  # PR_MESSAGE_ID
  MessageID => _ATT( $atp{String}, pack( 'H*', '8009' ) ),
  # PR_PARENT_ID
  ParentID => _ATT( $atp{String}, pack( 'H*', '800A' ) ),
  # PR_CONVERSATION_ID
  ConversationID => _ATT( $atp{String}, pack( 'H*', '800B' ) ),
  Body     => _ATT( $atp{Text},  pack( 'H*', '800C' ) ),    # PR_BODY
  # PR_IMPORTANCE
  Priority => _ATT( $atp{Short}, pack( 'H*', '800D' ) ),
  # PR_ATTACH_DATA_xxx
  AttachData => _ATT( $atp{Byte}, pack( 'H*', '800F' ) ),
  # PR_ATTACH_FILENAME
  AttachTitle => _ATT( $atp{String}, pack( 'H*', '8010' ) ),
  # PR_ATTACH_RENDERING
  AttachMetaFile => _ATT( $atp{Byte}, pack( 'H*', '8011' ) ),
  # PR_CREATION_TIME
  AttachCreateDate => _ATT( $atp{Date}, pack( 'H*', '8012' ) ),
  # PR_LAST_MODIFICATION_TIME
  AttachModifyDate => _ATT( $atp{Date}, pack( 'H*', '8013' ) ),
  # PR_LAST_MODIFICATION_TIME
  DateModified => _ATT( $atp{Date}, pack( 'H*', '8020' ) ),
  #PR_ATTACH_TRANSPORT_NAME
  AttachTransportFilename => _ATT( $atp{Byte}, pack( 'H*', '9001' ) ),
  AttachRenddata => _ATT( $atp{Byte}, pack( 'H*', '9002' ) ),
  MAPIProps      => _ATT( $atp{Byte}, pack( 'H*', '9003' ) ),
  # PR_MESSAGE_RECIPIENTS
  RecipTable           => _ATT( $atp{Byte}, pack( 'H*', '9004' ) ),
  Attachment           => _ATT( $atp{Byte},  pack( 'H*', '9005' ) ),
  TnefVersion          => _ATT( $atp{Dword}, pack( 'H*', '9006' ) ),
  OemCodepage          => _ATT( $atp{Byte},  pack( 'H*', '9007' ) ),
  # PR_ORIG_MESSAGE_CLASS
  OriginalMessageClass => _ATT( $atp{Word},  pack( 'H*', '0006' ) ),

  # PR_RCVD_REPRESENTING_xxx or PR_SENT_REPRESENTING_xxx
  Owner => _ATT( $atp{Byte}, pack( 'H*', '0000' ) ),
  # PR_SENT_REPRESENTING_xxx
  SentFor => _ATT( $atp{Byte}, pack( 'H*', '0001' ) ),
  # PR_RCVD_REPRESENTING_xxx
  Delegate => _ATT( $atp{Byte}, pack( 'H*', '0002' ) ),
  # PR_DATE_START
  DateStart => _ATT( $atp{Date}, pack( 'H*', '0006' ) ),
  DateEnd  => _ATT( $atp{Date}, pack( 'H*', '0007' ) ),  # PR_DATE_END
  # PR_OWNER_APPT_ID
  AidOwner => _ATT( $atp{Long}, pack( 'H*', '0008' ) ),
  # PR_RESPONSE_REQUESTED
  RequestRes => _ATT( $atp{Short}, pack( 'H*', '0009' ) ),
);

# Create reverse lookup table
%att_name = reverse %att;

# Global counter for creating file names
$g_file_cnt = 0;

# Set some package global defaults for new objects
# which can be overridden for any individual object.
%dflts = (
  debug               => 0,
  debug_max_display   => 1024,
  debug_max_line_size => 64,
  ignore_checksum     => 0,
  display_after_err   => 32,
  output_to_core      => 4096,
  output_dir          => File::Spec->curdir,
  output_prefix       => "tnef",
  buffer_size         => 1024,
);

# Make a file name
sub _mk_fname {
  my $parms = shift;
  File::Spec->catfile( $parms->{output_dir},
    $parms->{output_prefix} . "-" . $$ . "-"
      . ++$g_file_cnt . ".doc" );
}

sub _rtn_err {
  my ( $errmsg, $fh, $parms ) = @_;
  $errstr = $errmsg;
  if ( $parms->{debug} ) {
    my $read_size = $parms->{display_after_err} || 32;
    my $data;
    read($fh, $data, $read_size );
    print "Error: $errstr\n";
    print "Data:\n";
    print $1, "\n" while $data =~
      /([^\r\n]{0,$parms->{debug_max_line_size}})\r?\n?/g;
    print "HData:\n";
    my $hdata = unpack( "H*", $data );
    print $1, "\n"
      while $hdata =~ /(.{0,$parms->{debug_max_line_size}})/g;
  }
  return undef;
}

sub _read_err {
  my ( $bytes, $fh, $errmsg ) = @_;
  $errstr =
    ( defined $bytes ) ? "Premature EOF" : "Read Error:" . $errmsg;
  return undef;
}

sub read {
  croak "Usage: Matts::Message::TNEF->read(fh, parameters) "
    unless @_ == 2 or @_ == 3;
  my $self = shift;
  my $class = ref($self) || $self;
  $self = {};
  bless $self, $class;
  my ( $fd, $parms ) = @_;
  
  my %parms = %dflts;
  @parms{ keys %$parms } = values %$parms if defined $parms;
  $parms = \%parms;
  my $debug           = $parms{debug};
  my $ignore_checksum = $parms{ignore_checksum};

  # Start of TNEF stream
  my $data;
  my $num_bytes = read($fd, $data, 4 );
  return _read_err( $num_bytes, $fd, $! ) unless $num_bytes == 4;
  print "TNEF start: ", unpack( "H*", $data ), "\n" if $debug;
  return _rtn_err( "Not TNEF-encapsulated", $fd, $parms )
    unless $data eq $TNEF_SIGNATURE;

  # Key
  $num_bytes = read($fd, $data, 2 );
  return _read_err( $num_bytes, $fd, $! ) unless $num_bytes == 2;
  print "TNEF key: ", unpack( "H*", $data ), "\n" if $debug;

  # Start of First Object
  $num_bytes = read($fd, $data, 1 );
  return _read_err( $num_bytes, $fd, $! ) unless $num_bytes == 1;

  my $msg_att = "";

  my $is_msg = ( $data eq $LVL_MESSAGE );
  my $is_att = ( $data eq $LVL_ATTACHMENT );
  print "TNEF object start: ", unpack( "H*", $data ), "\n" if $debug;
  return _rtn_err( "Neither a message nor an attachment", $fd,
    $parms )
    unless $is_msg or $is_att;

  my $msg = Matts::Message::TNEF::Data->new;
  my @atts;

  # Current message or attachment in loop
  my $ent = $msg;

  # Read message and attachments
  LOOP: {
    my $type = $is_msg ? 'message' : 'attachment';
    print "Reading $type attribute\n" if $debug;
    $num_bytes = read($fd, $data, 4 );
    return _read_err( $num_bytes, $fd, $! ) unless $num_bytes == 4;
    my $att_id   = $data;
    my $att_name = $att_name{$att_id};

    print "TNEF $type attribute: ", unpack( "H*", $data ), "\n"
      if $debug;
    return _rtn_err( "Bad Attribute found in $type", $fd, $parms )
      unless $att_name{$att_id};
    if ( $att_id eq $att{TnefVersion} ) {
      return _rtn_err( "Version attribute found in attachment", $fd,
        $parms )
        if $is_att;
    } elsif ( $att_id eq $att{MessageClass} ) {
      return _rtn_err( "MessageClass attribute found in attachment",
        $fd, $parms )
        if $is_att;
    } elsif ( $att_id eq $att{AttachRenddata} ) {
      return _rtn_err( "AttachRenddata attribute found in message",
        $fd, $parms )
        if $is_msg;
      push @atts, ( $ent = Matts::Message::TNEF::Data->new );
    } else {
      return _rtn_err( "AttachRenddata must be first attribute", $fd,
        $parms )
        if $is_att
        and !@atts
        and $att_name ne "AttachRenddata";
    }
    print "Got attribute:$att_name{$att_id}\n" if $debug;

    $num_bytes = read($fd, $data, 4 );
    return _read_err( $num_bytes, $fd, $! ) unless $num_bytes == 4;

    print "HLength:", unpack( "H8", $data ), "\n" if $debug;
    my $length = unpack( "V", $data );
    print "Length: $length\n" if $debug;

    # Get the attribute data (returns an object since data may
    # actually end up in a file)
    my $calc_chksum;
    $data = _build_data( $fd, $length, \$calc_chksum, $parms )
      or return undef;
    _debug_print( $length, $att_id, $data, $parms ) if $debug;
    $ent->datahandle( $att_name, $data, $length );

    $num_bytes = read($fd, $data, 2 );
    return _read_err( $num_bytes, $fd, $! ) unless $num_bytes == 2;
    my $file_chksum = $data;
    if ($debug) {
      print "Calc Chksum:", unpack( "H*", $calc_chksum ), "\n";
      print "File Chksum:", unpack( "H*", $file_chksum ), "\n";
    }
    return _rtn_err( "Bad Checksum", $fd, $parms )
      unless $calc_chksum eq $file_chksum
      or $ignore_checksum;

    my $num_bytes = read($fd, $data, 1 );

    # EOF (0 bytes) is ok
    return _read_err( $num_bytes, $fd, $! ) unless defined $num_bytes;
    last LOOP if $num_bytes < 1;
    print "Next token:", unpack( "H2", $data ), "\n" if $debug;
    $is_msg = ( $data eq $LVL_MESSAGE );
    return _rtn_err( "Found message data in attachment", $fd, $parms )
      if $is_msg and $is_att;
    $is_att = ( $data eq $LVL_ATTACHMENT );
    redo LOOP if $is_msg or $is_att;
    return _rtn_err( "Not a TNEF $type", $fd, $parms );
  }

  print "EOF\n" if $debug;

  $self->{TN_Message}     = $msg;
  $self->{TN_Attachments} = \@atts;
  return $self;
}

sub _debug_print {
  my ( $length, $att_id, $data, $parms ) = @_;
  if ( $length < $parms->{debug_max_display} ) {
    $data = $data->data;
    if ( $att_id eq $att{TnefVersion} ) {
      $data = unpack( "L", $data );
      print "Version: $data\n";
    } elsif ( substr( $att_id, 2 ) eq $atp{Date} and $length == 14 ) {
      my ( $yr, $mo, $day, $hr, $min, $sec, $dow ) =
        unpack( "vvvvvvv", $data );
      my $date = join ":", $yr, $mo, $day, $hr, $min, $sec, $dow;
      print "Date: $date\n";
      print "HDate:", unpack( "H*", $data ), "\n";
    } elsif ( $att_id eq $att{AttachRenddata} and $length == 14 ) {
      my ( $atyp, $ulPosition, $dxWidth, $dyHeight, $dwFlags ) =
        unpack( "vVvvV", $data );
      $data = join ":", $atyp, $ulPosition, $dxWidth, $dyHeight,
        $dwFlags;
      print "AttachRendData: $data\n";
    } else {
      print "Data:\n";
      print $1, "\n" while $data =~
        /([^\r\n]{0,$parms->{debug_max_line_size}})\r?\n?/g;
      print "HData:\n";
      my $hdata = unpack( "H*", $data );
      print $1, "\n"
        while $hdata =~ /(.{0,$parms->{debug_max_line_size}})/g;
    }
  } else {
    my $io = $data->open("r")
      or croak "Error opening attachment data handle: $!";
    my $buffer;
    CORE::read($io, $buffer, $parms->{debug_max_display} );
    close($io) or croak "Error closing attachment data handle: $!";
    print "Data:\n";
    print $1, "\n" while $buffer =~
      /([^\r\n]{0,$parms->{debug_max_line_size}})\r?\n?/sg;
    print "HData:\n";
    my $hdata = unpack( "H*", $buffer );
    print $1, "\n"
      while $hdata =~ /(.{0,$parms->{debug_max_line_size}})/g;
  }
}

sub _build_data {
  my ( $fd, $length, $chksumref, $parms ) = @_;

  # Just borrow some other objects for the attachment attribute data
  my $body = new Matts::Message::TNEF::Body _mk_fname($parms);;
  $body->binmode(1);
  my $io     = $body->open("w");
  my $bufsiz = $parms->{buffer_size};
  $bufsiz = $length if $length < $bufsiz;
  my $buffer;
  my $chksum = 0;

  while ( $length > 0 ) {
    my $num_bytes = CORE::read($fd, $buffer, $bufsiz );
    return _read_err( $num_bytes, $fd, $! )
      unless $num_bytes == $bufsiz;
    $io->print($buffer);
    $chksum += unpack( "%16C*", $buffer );
    $chksum %= 65536;
    $length -= $bufsiz;
    $bufsiz = $length if $length < $bufsiz;
  }
  $$chksumref = pack( "v", $chksum );
  $io->close;
  return $body;
}

sub purge {
  my $self = shift;
  my $msg  = $self->{TN_Message};
  my @atts = $self->attachments;
  for ( keys %$msg ) {
    $msg->{$_}->purge if exists $att{$_};
  }
  for my $attch (@atts) {
    for ( keys %$attch ) {
      $attch->{$_}->purge if exists $att{$_};
    }
  }
}

sub message {
  my $self = shift;
  $self->{TN_Message};
}

sub attachments {
  my $self = shift;
  return @{ $self->{TN_Attachments} } if wantarray;
  $self->{TN_Attachments};
}

# This is for Messages or Attachments
# since they are essentially the same thing except
# for the leading attribute code
package Matts::Message::TNEF::Data;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  $self->{TN_Size} = {};
  bless $self, $class;
}

sub data {
  my $self = shift;
  my $attr = shift || 'AttachData';
  return $self->{$attr} && $self->{$attr}->as_string;
}

sub name {
  my $self = shift;
  my $attr = shift || 'AttachTitle';
  my $name = $self->{$attr} && $self->{$attr}->data;
  $name =~ s/\x00+$// if $name;
  return $name;
}

# Try to get the long filename out of the
# 'Attachment' attribute.
sub longname {
  my $self = shift;

  my $data = $self->data("Attachment");
  return unless $data;
  my $pos = index( $data, pack( "H*", "1e00013001" ) );
  return $self->name unless $pos >= 0;
  my $len = unpack( "V", substr( $data, $pos + 8, 4 ) );
  my $longname = substr( $data, $pos + 12, $len );
  $longname =~ s/\x00+$// if $longname;
  return $longname || $self->name;
}

sub datahandle {
  my $self = shift;
  my $attr = shift || 'AttachData';
  $self->{$attr} = shift if @_;
  $self->size( $attr, shift ) if @_;
  return $self->{$attr};
}

sub size {
  my $self = shift;
  my $attr = shift || 'AttachData';
  $self->{TN_Size}->{$attr} = shift if @_;
  return $self->{TN_Size}->{$attr};
}

package Matts::Message::TNEF::Body;

sub new {
    my $self = bless {}, shift;
    $self->init(@_);
    $self;
}

sub as_lines {
    my $self = shift;
    my @lines;
    my $io = $self->open("r") || return ();
    push @lines, $_ while (defined($_ = $io->getline()));
    $io->close;
    @lines;
}

sub as_string {
    my $self = shift;
    my $str = '';
    my $buf = '';
    my $io = $self->open("r") || return undef;
    my $nread = 0;
    $str .= $buf while ($nread = read($io, $buf, 2048));
    $io->close;
    return $str;
}
*data = \&as_string;         ### silenty invoke preferred usage

sub binmode {
    my ($self, $onoff) = @_;
    $self->{MB_Binmode} = $onoff if (@_ > 1);
    $self->{MB_Binmode};
}

sub dup {
    my $self = shift;
    bless { %$self }, ref($self);   ### shallow copy ok for ::File and ::Scalar
}

sub path {
    my $self = shift;
    $self->{MB_Path} = shift if @_;
    $self->{MB_Path};
}

sub print {
    my ($self, $fh) = @_;
    my $nread;

    ### Write it:
    my $buf = '';
    my $io = $self->open("r") || return undef;
    $fh->print($buf) while ($nread = read($io, $buf, 2048));
    $io->close;
    return defined($nread);    ### how'd we do?
}

sub init {
    my ($self, $path) = @_;
    $self->path($path);               ### use it as-is
    $self;
}

use FileHandle;

sub open {
    my ($self, $mode) = @_;
    my $IO;
    my $path = $self->path;
    if ($mode eq 'w') {          ### writing
        $IO = FileHandle->new(">$path") || die "write-open $path: $!";
    }
    elsif ($mode eq 'r') {       ### reading
        $IO = FileHandle->new("<$path") || die "read-open $path: $!";
    }
    else {
        die "bad mode: '$mode'";
    }
    CORE::binmode($IO) if $self->binmode;        ### set binary read/write mode?
    return $IO;
}

sub purge {
    my $self = shift;
    if (defined($self->path)) {
        unlink $self->path or die("couldn't unlink ".$self->path.": $!");
        $self->path(undef);
    }
    1;
}

1;
__END__
