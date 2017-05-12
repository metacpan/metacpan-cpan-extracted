use strict;
use warnings;
use 5.010;

package Email::Address::List;

our $VERSION = '0.05';
use Email::Address;

=head1 NAME

Email::Address::List - RFC close address list parsing

=head1 SYNOPSIS

    use Email::Address::List;

    my $header = <<'END';
    Foo Bar <simple@example.com>, (an obsolete comment),,,
     a group:
      a . weird . address @
      for-real .biz
     ; invalid thingy, <
     more@example.com
     >
    END

    my @list = Email::Address::List->parse($header);
    foreach my $e ( @list ) {
        if ($e->{'type'} eq 'mailbox') {
            print "an address: ", $e->{'value'}->format ,"\n";
        }
        else {
            print $e->{'type'}, "\n"
        }
    }

    # prints:
    # an address: "Foo Bar" <simple@example.com>
    # comment
    # group start
    # an address: a.weird.address@forreal.biz
    # group end
    # unknown
    # an address: more@example.com

=head1 DESCRIPTION

Parser for From, To, Cc, Bcc, Reply-To, Sender and
previous prefixed with Resent- (eg Resent-From) headers.

=head1 REASONING

L<Email::Address> is good at parsing addresses out of any text
even mentioned headers and this module is derived work
from Email::Address.

However, mentioned headers are structured and contain lists
of addresses. Most of the time you want to parse such field
from start to end keeping everything even if it's an invalid
input.

=head1 METHODS

=head2 parse

A class method that takes a header value (w/o name and :) and
a set of named options, for example:

    my @list = Email::Address::List->parse( $line, option => 1 );

Returns list of hashes. Each hash at least has 'type' key that
describes the entry. Types:

=over 4

=item mailbox

A mailbox entry with L<Email::Address> object under value key.

If mailbox has obsolete parts then 'obsolete' is true.

If address (not display-name/phrase or comments, but
local-part@domain) contains not ASCII chars then 'not_ascii' is
set to true. According to RFC 5322 not ASCII chars are not
allowed within mailbox. However, there are no big problems if
those are used and actually RFC 6532 extends a few rules
from 5322 with UTF8-non-ascii. Either use the feature or just
skip such addresses with skip_not_ascii option.

=item group start

Some headers with mailboxes may contain groupped addresses. This
element is returned for position where group starts. Under value
key you find name of the group. B<NOTE> that value is not post
processed at the moment, so it may contain spaces, comments,
quoted strings and other noise. Author willing to take patches
and warns that this will be changed at some point without additional
notifications, so if you need groups info then you better send a
patch :)

Groups can not be nested, but one field may have multiple groups or
mix of addresses that are in a group and not in any.

See skip_groups option.

=item group end

Returned when a group ends.

=item comment

Obsolete syntax allows one to use standalone comments between mailboxes
that can not be addressed to any mailbox. In such situations a comment
returned as an entry of this type. Comment itself is under value.

=item unknown

Returned if parser met something that shouldn't be there. Parser
tries to recover by jumping over to next comma (or semicolon if inside
group) that is out quoted string or comment, so "foo, bar, baz" string
results in three unknown entries. Jumping over comments and quoted strings
means that parser is very sensitive to unbalanced quotes and parens,
but it's on purpose.

=back

It can be controlled which elements are skipped, for example:

    Email::Address::List->parse($line, skip_unknown => 1, ...);

=over 4

=item skip_comments

Skips comments between mailboxes. Comments inside and next to a mailbox
are not skipped, but returned as part of mailbox entry.

=item skip_not_ascii

Skips mailboxes where address part has not ASCII characters.

=item skip_groups

Skips group starts and end elements, however emails within groups are
still returned.

=item skip_unknown

Skip anything that is not recognizable. It still tries to recover as
described earlier.

=back

=cut

#   mailbox         =   name-addr / addr-spec
#   display-name    =   phrase
#
#   from            =   "From:" mailbox-list CRLF
#   sender          =   "Sender:" mailbox CRLF
#   reply-to        =   "Reply-To:" address-list CRLF
#
#   to              =   "To:" address-list CRLF
#   cc              =   "Cc:" address-list CRLF
#   bcc             =   "Bcc:" [address-list / CFWS] CRLF
#
#   resent-from     =   "Resent-From:" mailbox-list CRLF
#   resent-sender   =   "Resent-Sender:" mailbox CRLF
#   resent-to       =   "Resent-To:" address-list CRLF
#   resent-cc       =   "Resent-Cc:" address-list CRLF
#   resent-bcc      =   "Resent-Bcc:" [address-list / CFWS] CRLF
#
#   obs-from        =   "From" *WSP ":" mailbox-list CRLF
#   obs-sender      =   "Sender" *WSP ":" mailbox CRLF
#   obs-reply-to    =   "Reply-To" *WSP ":" address-list CRLF
#
#   obs-to          =   "To" *WSP ":" address-list CRLF
#   obs-cc          =   "Cc" *WSP ":" address-list CRLF
#   obs-bcc         =   "Bcc" *WSP ":" (address-list / (*([CFWS] ",") [CFWS])) CRLF
#
#   obs-resent-from =   "Resent-From" *WSP ":" mailbox-list CRLF
#   obs-resent-send =   "Resent-Sender" *WSP ":" mailbox CRLF
#   obs-resent-date =   "Resent-Date" *WSP ":" date-time CRLF
#   obs-resent-to   =   "Resent-To" *WSP ":" address-list CRLF
#   obs-resent-cc   =   "Resent-Cc" *WSP ":" address-list CRLF
#   obs-resent-bcc  =   "Resent-Bcc" *WSP ":" (address-list / (*([CFWS] ",") [CFWS])) CRLF
#   obs-resent-mid  =   "Resent-Message-ID" *WSP ":" msg-id CRLF
#   obs-resent-rply =   "Resent-Reply-To" *WSP ":" address-list CRLF

our $COMMENT_NEST_LEVEL ||= 2;

our %RE;
our %CRE;

$RE{'CTL'}            = q{\x00-\x1F\x7F};
$RE{'special'}        = q{()<>\\[\\]:;@\\\\,."};

$RE{'text'}           = qr/[^\x0A\x0D]/;

$RE{'quoted_pair'}    = qr/\\$RE{'text'}/;

$RE{'atext'}          = qr/[^$RE{'CTL'}$RE{'special'}\s]/;
$RE{'ctext'}          = qr/(?>[^()\\]+)/;
$RE{'qtext'}          = qr/[^\\"]/;
$RE{'dtext'}          = qr/[^\[\]\\]/;

($RE{'ccontent'}, $RE{'comment'}) = (q{})x2;
for (1 .. $COMMENT_NEST_LEVEL) {
  $RE{'ccontent'} = qr/$RE{'ctext'}|$RE{'quoted_pair'}|$RE{'comment'}/;
  $RE{'comment'}  = qr/\s*\((?:\s*$RE{'ccontent'})*\s*\)\s*/;
}
$RE{'cfws'}           = qr/$RE{'comment'}|\s+/;

$RE{'qcontent'}       = qr/$RE{'qtext'}|$RE{'quoted_pair'}/;
$RE{'quoted-string'}  = qr/$RE{'cfws'}*"$RE{'qcontent'}+"$RE{'cfws'}*/;

$RE{'atom'}           = qr/$RE{'cfws'}*$RE{'atext'}++$RE{'cfws'}*/;

$RE{'word'}           = qr/$RE{'cfws'}* (?: $RE{'atom'} | "$RE{'qcontent'}+" ) $RE{'cfws'}*/x;
$RE{'phrase'}         = qr/$RE{'word'}+/x;
$RE{'display-name'}   = $RE{'phrase'};

$RE{'dot_atom_text'}  = qr/$RE{'atext'}+(?:\.$RE{'atext'}+)*/;
$RE{'dot_atom'}       = qr/$RE{'cfws'}*$RE{'dot_atom_text'}$RE{'cfws'}*/;
$RE{'local-part'}     = qr/$RE{'dot_atom'}|$RE{'quoted-string'}/;

$RE{'dcontent'}       = qr/$RE{'dtext'}|$RE{'quoted_pair'}/;
$RE{'domain_literal'} = qr/$RE{'cfws'}*\[(?:\s*$RE{'dcontent'})*\s*\]$RE{'cfws'}*/;
$RE{'domain'}         = qr/$RE{'dot_atom'}|$RE{'domain_literal'}/;

$RE{'addr-spec'}      = qr/$RE{'local-part'}\@$RE{'domain'}/;
$RE{'angle-addr'}     = qr/$RE{'cfws'}* < $RE{'addr-spec'} > $RE{'cfws'}*/x;

$RE{'name-addr'}      = qr/$RE{'display-name'}?$RE{'angle-addr'}/;
$RE{'mailbox'}        = qr/(?:$RE{'name-addr'}|$RE{'addr-spec'})$RE{'comment'}*/;

$CRE{'addr-spec'}      = qr/($RE{'local-part'})\@($RE{'domain'})/;
$CRE{'mailbox'} = qr/
    (?:
        ($RE{'display-name'})?($RE{'cfws'}*)<$CRE{'addr-spec'}>($RE{'cfws'}*)
        |$CRE{'addr-spec'}
    )($RE{'comment'}*)
/x;

$RE{'dword'}            = qr/$RE{'cfws'}* (?: $RE{'atom'} | \. | "$RE{'qcontent'}+" ) $RE{'cfws'}*/x;
$RE{'obs-phrase'}       = qr/$RE{'word'} $RE{'dword'}*/x;
$RE{'obs-display-name'} = $RE{'obs-phrase'};
$RE{'obs-route'}        = qr/
    (?:$RE{'cfws'}|,)*
    \@$RE{'domain'}
    (?:,$RE{'cfws'}?(?:\@$RE{'domain'})?)*
    :
/x;
$RE{'obs-domain'}       = qr/$RE{'atom'}(?:\.$RE{'atom'})*|$RE{'domain_literal'}/;
$RE{'obs-local-part'}   = qr/$RE{'word'}(?:\.$RE{'word'})*/;
$RE{'obs-addr-spec'}    = qr/$RE{'obs-local-part'}\@$RE{'obs-domain'}/;
$CRE{'obs-addr-spec'}   = qr/($RE{'obs-local-part'})\@($RE{'obs-domain'})/;
$CRE{'obs-mailbox'} = qr/
    (?:
        ($RE{'obs-display-name'})?
        ($RE{'cfws'}*)< $RE{'obs-route'}? $CRE{'obs-addr-spec'} >($RE{'cfws'}*)
        |$CRE{'obs-addr-spec'}
    )($RE{'comment'}*)
/x;

sub parse {
    my $self = shift;
    my %args = @_%2? (line => @_) : @_;
    my $line = delete $args{'line'};

    my $in_group = 0;

    my @res;
    while ($line =~ /\S/) {
        # in obs- case we have number of optional comments/spaces/
        # address-list    =   (address *("," address)) / obs-addr-list
        # obs-addr-list   =   *([CFWS] ",") address *("," [address / CFWS]))
        if ( $line =~ s/^(?:($RE{'cfws'})?,)//o ) {
            push @res, {type => 'comment', value => $1 }
                if $1 && !$args{'skip_comments'} && $1 =~ /($RE{'comment'})/;
            next;
        }
        $line =~ s/^\s+//o;

        # now it's only comma separated address where address is:
        # address         =   mailbox / group

        # deal with groups
        # group           =   display-name ":" [group-list] ";" [CFWS]
        # group-list      =   mailbox-list / CFWS / obs-group-list
        # obs-group-list  =   1*([CFWS] ",") [CFWS])
        if ( !$in_group && $line =~ s/^($RE{'display-name'})://o ) {
            push @res, {type => 'group start', value => $1 }
                unless $args{'skip_groups'};
            $in_group = 1; next;
        }
        if ( $in_group && $line =~ s/^;// ) {
            push @res, {type => 'group end'} unless $args{'skip_groups'};
            $in_group = 0; next;
        }

        # now we got rid of groups and cfws, 'address = mailbox'
        # mailbox-list    =   (mailbox *("," mailbox)) / obs-mbox-list
        # obs-mbox-list   =   *([CFWS] ",") mailbox *("," [mailbox / CFWS]))

        # so address-list is now comma separated list of mailboxes:
        # address-list    = (mailbox *("," mailbox))
        my $obsolete = 0;
        if ( $line =~ s/^($CRE{'mailbox'})($RE{cfws}*)(?=,|;|$)//o
            || ($line =~ s/^($CRE{'obs-mailbox'})($RE{cfws}*)(?=,|;|$)//o and $obsolete = 1)
        ) {
            my ($original, $phrase, $user, $host, @comments) = $self->_process_mailbox(
                $1,$2,$3,$4,$5,$6,$7,$8,$9
            );
            my $not_ascii = "$user\@$host" =~ /\P{ASCII}/? 1 : 0;
            next if $not_ascii && $args{skip_not_ascii};

            push @res, {
                type => 'mailbox',
                value => Email::Address->new(
                    $phrase, "$user\@$host", join(' ', @comments),
                    $original,
                ),
                obsolete => $obsolete,
                not_ascii => $not_ascii,
            };
            next;
        }

        # if we got here then something unknown on our way
        # try to recorver
        if ($in_group) {
            if ( $line =~ s/^([^;,"\)]*(?:(?:$RE{'quoted-string'}|$RE{'comment'})[^;,"\)]*)*)(?=;|,)//o ) {
                push @res, { type => 'unknown', value => $1 } unless $args{'skip_unknown'};
                next;
            }
        } else {
            if ( $line =~ s/^([^,"\)]*(?:(?:$RE{'quoted-string'}|$RE{'comment'})[^,"\)]*)*)(?=,)//o ) {
                push @res, { type => 'unknown', value => $1 } unless $args{'skip_unknown'};
                next;
            }
        }
        push @res, { type => 'unknown', value => $line } unless $args{'skip_unknown'};
        last;
    }
    return @res;
}

my $dequote = sub {
    local $_ = shift;
    s/^"//; s/"$//; s/\\(.)/$1/g;
    return "$_";
};
my $quote = sub {
    local $_ = shift;
    s/([\\"])/\\$1/g;
    return qq{"$_"};
};

sub _process_mailbox {
    my $self = shift;
    my $original = shift;
    my @rest = (@_);

    my @comments;
    foreach ( grep defined, splice @rest ) {
        s{ ($RE{'quoted-string'}) | ($RE{comment}) }
         { $1? $1 : do { push @comments, $2; $comments[-1] =~ /^\s|\s$/? ' ' : '' } }xgoe;
        s/^\s+//; s/\s+$//;
        next unless length;

        push @rest, $_;
    }
    my ($host, $user, $phrase) = reverse @rest;

    # deal with spaces out of quoted strings
    s{ ($RE{'quoted-string'}) | \s+ }{ $1? $1 : ' ' }xgoe
        foreach grep defined, $phrase;
    s{ ($RE{'quoted-string'}) | \s+ }{ $1? $1 : '' }xgoe
        foreach $user, $host;

    # dequote
    s{ ($RE{'quoted-string'}) }{ $dequote->($1) }xgoe
        foreach grep defined, $phrase, $user;
    $user = $quote->($user) unless $user =~ /^$RE{'dot_atom'}$/;

    @comments = grep length, map { s/^\s+//; s/\s+$//; $_ } grep defined, @comments;
    return $original, $phrase, $user, $host, @comments;
}


=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as Perl itself.

=cut

1;
