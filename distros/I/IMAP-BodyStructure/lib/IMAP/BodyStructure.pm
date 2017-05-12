package IMAP::BodyStructure;
use strict;

=head1 NAME

IMAP::BodyStructure - IMAP4-compatible BODYSTRUCTURE and ENVELOPE parser

=head1 SYNOPSIS
    
    use IMAP::BodyStructure;

    # $imap is a low-level IMAP-client with an ability to fetch items
    # by message uids

    my $bs = new IMAP::BodyStructure
        $imap->imap_fetch($msg_uid,
                'BODYSTRUCTURE', 1)->[0]->{BODYSTRUCTURE};

    print "[UID:$msg_uid] message is in Russian. Sure.\n"
        if $bs->charset =~ /(?:koi8-r|windows-1251)/i;

    my $part = $bs->part_at('1.3');
    $part->type =~ m#^image/#
        and print "The 3rd part is an image named \""
            . $part->filename . "\"\n";

=head1 DESCRIPTION

An IMAP4-compatible IMAP server MUST include a full MIME-parser which
parses the messages inside IMAP mailboxes and is accessible via
BODYSTRUCTURE fetch item. This module provides a Perl interface to
parse the output of IMAP4 MIME-parser. Hope no one will have problems
with parsing this doc.

It is a rather straightforward C<m/\G.../gc>-style parser and is
therefore much, much faster then the venerable L<Mail::IMAPClient::BodyStructure>
which is based on a L<Parse::RecDescent> grammar. I believe it is also
more correct when parsing nested multipart C<message/rfc822> parts. See
testsuite if interested.

I'd also like to emphasize that I<this module does not contain IMAP4
client!> You will need to employ one from CPAN, there are many. A
section with examples of getting to a BODYSTRUCTURE fetch item with
various Perl IMAP clients available on CPAN would greatly
enhance this document.

=head1 INTERFACE

=cut

use 5.005;

use vars qw/$VERSION/;

$VERSION = '1.03';

sub _get_envelope($\$);
sub _get_bodystructure(\$;$$);
sub _get_npairs(\$);
sub _get_ndisp(\$);
sub _get_nstring(\$);
sub _get_lang(\$);

=head2 METHODS

=over 4

=item new($)

The constructor does most of the work here. It initializes the
hierarchial data structure representing all the message parts and their
properties. It takes one argument which should be a string returned
by IMAP server in reply to a FETCH command with BODYSTRUCTURE item.

All the parts on all the levels are represented by IMAP::BodyStructure
objects and that enables the uniform access to them. It is a direct
implementation of the Composite Design Pattern.

=cut

use fields qw/type encoding size disp params parts desc bodystructure
    part_id cid textlines md5 lang loc envelope/;

sub new {
    my $class   = shift;
    $class      = ref $class || $class;
    my $imap_str= shift;

    return _get_bodystructure($imap_str, $class);
}

=item type()

Returns the MIME type of the part. Expect something like C<text/plain>
or C<application/octet-stream>.

=item encoding()

Returns the MIME encoding of the part. This is usually one of '7bit',
'8bit', 'base64' or 'quoted-printable'.

=item size()

Returns the size of the part in octets. It is I<NOT> the size of the
data in the part, which may be encoded as quoted-printable leaving us
without an obvious method of calculating the exact size of original
data.

=cut

for my $field (qw/type encoding size/) {
    no strict 'refs';
    *$field = sub { return $_[0]->{$field} };
}

=item disp()

Returns the content-disposition of the part. One of 'inline' or
'attachment', usually. Defaults to inline, but you should remember
that if there IS a disposition but you cannot recognize it than act as
if it's 'attachment'. And use case-insensitive comparisons.

=cut

sub disp {
    my $self = shift;

    return $self->{disp} ? $self->{disp}->[0] || 'inline' : 'inline';
}

=item charset()

Returns the charset of the part OR the charset of the first nested
part. This looks like a good heuristic really. Charset is something
resembling 'UTF-8', 'US-ASCII', 'ISO-8859-13' or 'KOI8-R'. The standard
does not say it should be uppercase, by the way.

Can be undefined.

=cut

sub charset {
    my $self = shift;

    # get charset from params OR dive into the first part
    return $self->{params}->{charset}
        || ($self->{parts} && @{$self->{parts}} && $self->{parts}->[0]->charset)
        || undef;   # please oh please, no '' or '0' charsets
}

=item filename()

Returns the filename specified as a part of Content-Disposition
header.

Can be undefined.

=cut

sub filename {
    my $self = shift;

    return $self->{disp}->[1]->{filename};
}

=item description()

Returns the description of the part.

=cut

sub description {
    my $self = shift;

    return $self->{desc};
}

=item parts(;$)

This sub acts differently depending on whether you pass it an
argument or not.

Without any arguments it returns a list of parts in list context and
the number in scalar context.

Specifying a scalar argument allows you to get an individual part with
that index.

I<Remember, all the parts I talk here about are not actual message data, files
etc. but IMAP::BodyStructure objects containing information about the
message parts which was extracted from parsing BODYSTRUCTURE IMAP
response!>

=cut

sub parts {
    my $self = shift;
    my $arg = shift;

    if (defined $arg) {
        return $self->{parts}->[$arg];
    } else {
        return wantarray ? @{$self->{parts}} : scalar @{$self->{parts}};
    }
}

=item part_at($)

This method returns a message part by its path. A path to a part in
the hierarchy is a dot-separated string of part indices. See L</SYNOPSIS> for
an example. A nested C<message/rfc822> does not add a hierarchy level
UNLESS it is a single part of another C<message/rfc822> part (with no
C<multipart/*> levels in between).  Instead, it has an additional
C<.TEXT> part which refers to the internal IMAP::BodyStructure object.
Look, here is an outline of an example message structure with part
paths alongside each part.

    multipart/mixed                   1
        text/plain                    1.1
        application/msword            1.2
        message/rfc822                1.3
            multipart/alternative     1.3.TEXT
                text/plain            1.3.1
                multipart/related     1.3.2
                    text/html         1.3.2.1
                    image/png         1.3.2.2
                    image/png         1.3.2.3

This is a text email with two attachments, one being an MS Word document,
and the other is itself a message (probably a forward) which is composed in a
graphical MUA and contains two alternative representations, one
plain text fallback and one HTML with images (bundled as a
C<multipart/related>).

Another one with several levels of C<message/rfc822>. This one is hard
to compose in a modern MUA, however.

    multipart/mixed                   1
        text/plain                    1.1
        message/rfc822                1.2
            message/rfc822            1.2.TEXT
                text/plain            1.2.1

=cut

sub part_at {
    my $self = shift;
    my $path = shift;

    return $self->_part_at(split /\./, $path);
}

sub _part_at {
    my $self = shift;
    my @parts = @_;

    return $self unless @parts; # (cond ((null? l) s)

    my $part_num = shift @parts; # (car l)

    if ($self->type =~ /^multipart\//) {
        if (exists $self->{parts}->[$part_num - 1]) {
            return $self->{parts}->[$part_num - 1]->_part_at(@parts);
        } else {
            return;
        }
    } elsif ($self->type eq 'message/rfc822') {
        return $self->{bodystructure} if $part_num eq 'TEXT';

        if ($self->{bodystructure}->type =~ m{^ multipart/ | ^ message/rfc822 \z}xms) {
            return $self->{bodystructure}->_part_at($part_num, @parts);
        } else {
            return $part_num == 1 ? $self->{bodystructure}->_part_at(@parts) : undef;
        }
    } else {
        # there's no included parts in single non-rfc822 parts
        # so if you still want one you get undef
        if ($part_num && $part_num ne '1' || @parts) {
            return;
        } else {
            return $self;
        }
    }
}

=item part_path()

Returns the part path to the current part.

=back

=head2 DATA MEMBERS

These are additional pieces of information returned by IMAP server and
parsed. They are rarely used, though (and rarely defined too, btw), so
I chose not to provide access methods for them.

=over 4

=item params

This is a hashref of MIME parameters. The only interesting param is
charset and there's a shortcut method for it.

=item lang

Content language.

=item loc

Content location.

=item cid

Content ID.

=item md5

Content MD5. No one seems to bother with calculating and it is usually
undefined.

=back

B<cid> and B<md5> members exist only in singlepart parts.

=cut

sub part_path {
    my $self = shift;

    return $self->{part_id};
}

sub _get_envelope($\$) {
    eval "$_[0]::Envelope->new(\$_[1])";
}

sub _get_bodystructure(\$;$$) {
    my $str     = shift;
    my $class   = shift || __PACKAGE__;
    my $id      = shift;

    my __PACKAGE__ $bs = fields::new($class);
    $bs->{part_id} = $id || 1;  # !defined $id --> top-level message
                                # and single-part has one part with part_id 1

    my $id_prefix = $id ? "$id." : '';

    $$str =~ m/\G\s*(?:\(BODYSTRUCTURE\s*)?\(/gc
        or return 0;

    $bs->{parts}      = [];
    if ($$str =~ /\G(?=\()/gc) {
        # multipart
        $bs->{type}       = 'multipart/';
        my $part_id = 1;
        $id_prefix =~ s/\.?TEXT//;
        while (my $part_bs = _get_bodystructure($$str, $class, $id_prefix . $part_id++)) {
            push @{$bs->{parts}}, $part_bs;
        }

        $bs->{type}      .= lc(_get_nstring($$str));
        $bs->{params}     = _get_npairs($$str);
        $bs->{disp}       = _get_ndisp($$str);
        $bs->{lang}       = _get_lang($$str);
        $bs->{loc}        = _get_nstring($$str);
    } else {
        $bs->{type}       = lc (_get_nstring($$str) . '/' . _get_nstring($$str));
        $bs->{params}     = _get_npairs($$str);
        $bs->{cid}        = _get_nstring($$str);
        $bs->{desc}       = _get_nstring($$str);
        $bs->{encoding}   = _get_nstring($$str);
        $bs->{size}       = _get_nstring($$str);

        if ($bs->{type} eq 'message/rfc822') {
            $bs->{envelope}       = _get_envelope($class, $$str);
            if ($id_prefix =~ s/\.?TEXT//) {
                $bs->{bodystructure}  = _get_bodystructure($$str, $class, $id_prefix . '1');
            } else {
                $bs->{bodystructure}  = _get_bodystructure($$str, $class, $id_prefix . 'TEXT');
            }
            $bs->{textlines}      = _get_nstring($$str);
        } elsif ($bs->{type}      =~ /^text\//) {
            $bs->{textlines}      = _get_nstring($$str);
        }

        $bs->{md5}  = _get_nstring($$str);
        $bs->{disp} = _get_ndisp($$str);
        $bs->{lang} = _get_lang($$str);
        $bs->{loc}  = _get_nstring($$str);
    }

    $$str =~ m/\G\s*\)/gc;

    return $bs;
}

sub _get_ndisp(\$) {
    my $str = shift;

    $$str =~ /\G\s+/gc;

    if ($$str =~ /\GNIL/gc) {
        return undef;
    } elsif ($$str =~ m/\G\s*\(/gc) {
        my @disp;

        $disp[0] = _get_nstring($$str);
        $disp[1] = _get_npairs($$str);

        $$str =~ m/\G\s*\)/gc;
        return \@disp;
    }
    
    return 0;
}

sub _get_npairs(\$) {
    my $str = shift;

    $$str =~ /\G\s+/gc;

    if ($$str =~ /\GNIL/gc) {
        return undef;
    } elsif ($$str =~ m/\G\s*\(/gc) {
        my %r;
        while ('fareva') {
            my ($key, $data) = (_get_nstring($$str), _get_nstring($$str));
            $key or last;

            $r{$key} = $data;
        }

        $$str =~ m/\G\s*\)/gc;
        return \%r;
    }
    
    return 0;
}

sub _get_nstring(\$) {
    my $str = $_[0];

    # nstring         = string / nil
    # nil             = "NIL"
    # string          = quoted / literal
    # quoted          = DQUOTE *QUOTED-CHAR DQUOTE
    # QUOTED-CHAR     = <any TEXT-CHAR except quoted-specials> /
    #                  "\" quoted-specials
    # quoted-specials = DQUOTE / "\"
    # literal         = "{" number "}" CRLF *CHAR8
    #                    ; Number represents the number of CHAR8s

    # astring = 1*(any CHAR except "(" / ")" / "{" / SP / CTL / list-wildcards / quoted-specials)

    $$str =~ /\G\s+/gc;

    if ($$str =~ /\GNIL/gc) {
        return undef;
    } elsif ($$str =~ m/\G(\"(?>[^\\\"]*(?:\\.[^\\\"]*)*)\")/gc) { # delimited re ala Regexp::Common::delimited + (?>...)
        return _unescape($1);
    } elsif ($$str =~ /\G\{(\d+)\}\r\n/gc) {
        my $pos = pos($$str);
        my $data = substr $$str, $pos, $1;
        pos($$str) = $pos + $1;
        return $data;
    } elsif ($$str =~ /\G([^"\(\)\{ \%\*\"\\\x00-\x1F]+)/gc) {
        return $1;
    }

    return 0;
}

sub _get_lang(\$) {
    my $str = $_[0];

    # body-fld-lang   = nstring / "(" string *(SP string) ")"

    if ($$str =~ m/\G\s*\(/gc) {
        my @a;
        while ('fareva') {
            my $data = _get_nstring($$str);
            $data or last;

            push @a, $data;
        }

        $$str =~ m/\G\s*\)/gc;
        return \@a;
    }

    if (my $data = _get_nstring($$str)) {
        return [$data];
    }

    return [];
}

sub _unescape {
    my $str = shift;

    $str =~ s/^"//;
    $str =~ s/"$//;
    $str =~ s/\\\"/\"/g;
    $str =~ s/\\\\/\\/g;

    return $str;
}

=over 4

=item get_enveleope($)

Parses a string into IMAP::BodyStructure::Envelope object. See below.

=back

=head2 IMAP::BodyStructure::Envelope CLASS

Every message on an IMAP server has an envelope. You can get it
using ENVELOPE fetch item or, and this is relevant, from BODYSTRUCTURE
response in case there are some nested messages (parts with type of
C<message/rfc822>). So, if we have a part with such a type then the
corresponding IMAP::BodyStructure object always has
B<envelope> data member which is, in turn, an object of
IMAP::BodyStructure::Envelope.

You can of course use this satellite class on its own, this is very
useful when generating meaningful message lists in IMAP folders.

=cut

package IMAP::BodyStructure::Envelope;

sub _get_nstring(\$); # proto

*_get_nstring = \&IMAP::BodyStructure::_get_nstring;

sub _get_naddrlist(\$);
sub _get_naddress(\$);

use vars qw/@envelope_addrs/;
@envelope_addrs = qw/from sender reply_to to cc bcc/;

=head2 METHODS

=over 4

=item new($)

The constructor create Envelope object from string which should be an
IMAP server respone to a fetch with ENVELOPE item or a substring of
BODYSTRUCTURE response for a message with message/rfc822 parts inside.

=back

=head2 DATA MEMBERS

=over 4

=item date

Date of the message as specified in the envelope. Not the IMAP
INTERNALDATE, be careful!

=item subject

Subject of the message, may be RFC2047 encoded, of course.

=item message_id

=item in_reply_to

Message-IDs of the current message and the message in reply to which
this one was composed.

=item to, from, cc, bcc, sender, reply_to

These are the so called address-lists or just arrays of addresses.
Remember, a message may be addressed to lots of people.

Each address is a hash of four elements:

=over 4

=item name

The informal part, "A.U.Thor" from "A.U.Thor, <a.u.thor@somewhere.com>"

=item sroute

Source-routing information, not used. (By the way, IMAP4r1 spec was
born after the last email address with sroute passed away.)

=item account

The part before @.

=item host

The part after @.

=item full

The full address for display purposes.

=back

=back

=cut

use fields qw/from sender reply_to to cc bcc date subject in_reply_to message_id/;

sub new(\$) {
    my $class = shift;
    my $str = shift;
    
    $$str =~ m/\G\s*(?:\(ENVELOPE)?\s*\(/gc
        or return 0;

    my __PACKAGE__ $self = fields::new($class);

    $self->{'date'}     = _get_nstring($$str);
    $self->{'subject'}  = _get_nstring($$str);

    foreach my $header (@envelope_addrs) {
        $self->{$header} = _get_naddrlist($$str);
    }

    $self->{'in_reply_to'}  = _get_nstring($$str);
    $self->{'message_id'}   = _get_nstring($$str);

    $$str =~ m/\G\s*\)/gc;

    return $self;
}

sub _get_naddress(\$) {
    my $str = shift;

    if ($$str =~ /\GNIL/gc) {
        return undef;
    } elsif ($$str =~ m/\G\s*\(/gc) {
        my %addr = (
            name    => _get_nstring($$str),
            sroute  => _get_nstring($$str),
            account => _get_nstring($$str),
            host    => _get_nstring($$str),
        );
        $addr{address} = ($addr{account}
                ? "$addr{account}@" . ($addr{host} || '')
                : '');

        $addr{full} = _format_address($addr{name}, $addr{address});

        $$str =~ m/\G\s*\)/gc;
        return \%addr;
    }
    return 0;
}

sub _get_naddrlist(\$) {
    my $str = shift;
    
    $$str =~ /\G\s+/gc;

    if ($$str =~ /\GNIL/gc) {
        return undef;
    } elsif ($$str =~ m/\G\s*\(/gc) {
        my @addrs = ();
        while (my $addr = _get_naddress($$str)) {
            push @addrs, $addr;
        }

        $$str =~ m/\G\s*\)/gc;
        return \@addrs;
    }
    return 0;
}

my $rfc2822_atext = q(a-zA-Z0-9!#$%&'*+/=?^_`{|}~-);   # simple non-interpolating string (think apostrophs)
my $rfc2822_atom = qr/[$rfc2822_atext]+/; # straight from rfc2822

use constant EMPTY_STR => q{};
sub _format_address {
    my ($phrase, $email) = @_;

    if (defined $phrase && $phrase ne EMPTY_STR) {
        if ($phrase !~ /^ \s* " [^"]+ " \s* \z/xms) {
            # $phrase is not already quoted

            $phrase =~ s/ (["\\]) /\\$1/xmsg;

            if ($phrase !~ m/^ \s* $rfc2822_atom (?: \s+ $rfc2822_atom)* \s* \z/xms) {
                $phrase = qq{"$phrase"};
            }
        }

        return $email ? "$phrase <$email>" : $phrase;
    } else {
        return $email || '';
    }
}

1;

__END__
=head1 EXAMPLES

The usual way to determine if an email has some files attached (in
order to display a cute little scrap in the message list, e.g.) is to
check whether the message is multipart or not. This method tends to
give many false positives on multipart/alternative messages with a
HTML and plaintext parts and no files. The following sub tries to be a
little smarter.

    sub _has_files {
        my $bs = shift;

        return 1 if $bs->{type} !~ m#^(?:text|multipart)/#;

        if ($bs->{type} =~ m#^multipart/#) {
            foreach my $part (@{$bs->{parts}}) {
                return 1 if _has_files($part);
            }
        }

        return 0;
    }

This snippet selects a rendering routine for a message part.

    foreach (
        [ qr{text/plain}            => \&_render_textplain  ],
        [ qr{text/html}             => \&_render_texthtml   ],
        [ qr{multipart/alternative} => \&_render_alt        ],
        [ qr{multipart/mixed}       => \&_render_mixed      ],
        [ qr{multipart/related}     => \&_render_related    ],
        [ qr{image/}                => \&_render_image      ],
        [ qr{message/rfc822}        => \&_render_rfc822     ],
        [ qr{multipart/parallel}    => \&_render_mixed      ],
        [ qr{multipart/report}      => \&_render_mixed      ],
        [ qr{multipart/}            => \&_render_mixed      ],
        [ qr{text/}                 => \&_render_textplain  ],
        [ qr{message/delivery-status}=> \&_render_textplain ],
    ) {
        $bs->type =~ $_->[0]
            and $renderer = $_->[1]
            and last;
    }

=head1 BUGS

Shouldn't be any, as this is a simple parser of a standard structure.

=head1 AUTHOR

Alex Kapranoff <alex@kapranoff.ru>

=head1 ACKNOWLEDGMENTS

Jonas Liljegren contributed support for multivalued "lang" items.

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2015 by Alex Kapranoff <alex@kapranoff.ru>.

This is free software; you can redistribute it and/or modify it under
the terms GNU General Public License version 3.

=head1 SEE ALSO

L<Mail::IMAPClient>, L<Net::IMAP::Simple>, RFC3501, RFC2045, RFC2046.

=cut
