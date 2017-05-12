package Mail::POP3::Folder::webscrape;

# concepts:
# a "listpage" is returned by the initial get_fill_submit which is parsed into:
# a "listpage" is parsed into:
# { items => \@items, pageno => $pageno, num_pages => $num_pages,
#      nextlink => $nextlink, }
# an "item" is +{ id => $id, url => $url, }
# the item url points to a "page" which is parsed into

use strict;
use HTML::Entities;
use HTML::Form;
use HTTP::Cookies;
use HTTP::Request::Common;
use URI::URL;

my $formno = 0; # form_fill
# this is at top so $DEBUG in L::UA::RNOk is correct one!
our $DEBUG = 0; # form_fill, redirect_cookie_loop et al
my $req_count = 0; # redirect_cookie_loop et al
require Data::Dumper if $DEBUG; # form_fill
my $CRLF = "\015\012";

{
    # redirect_cookie_loop et al
    package LWP::UserAgent::RedirectNotOk;
    use base qw(LWP::UserAgent);
    sub redirect_ok { print "Redirecting...\n" if $DEBUG; 0 }
}

sub new {
    my (
        $class,
        $user_name,
        $password,
        $starturl, # from the config file
	$userfieldnames, # listref same order as values supplied in USER
        $otherfields, # hash fieldname => value
	$listre, # field => RE; fields: pageno, num_pages, nextlink, itemurls
	$itemre, # hash extractfield => RE to get it from "page"
	$itempostpro, # extractfield => sub returns pairS of field/value
	$itemurl2id, # sub taking URL, returns unique, persistent item ID
	$itemformat, # takes item hash, returns email message
	$messagesize,
    ) = @_;
    my $self = {};
    bless $self, $class;
    $user_name =~ s#\+# #g; # no spaces allowed in POP3, so "+" instead
    my @userfieldvalues = split /:/, $user_name;
    $self->{STARTURL} = $starturl;
    $self->{FIELDS} = { %$otherfields }; # copy just in case
    map {
	$self->{FIELDS}->{$userfieldnames->[$_]} = $userfieldvalues[$_];
    } 0..$#{$userfieldnames};
    $self->{LISTRE} = $listre;
    $self->{ITEMRE} = $itemre;
    $self->{ITEMPOSTPRO} = $itempostpro;
    $self->{ITEMURL2ID} = $itemurl2id;
    $self->{ITEMFORMAT} = $itemformat;
    $self->{MESSAGESIZE} = $messagesize;
    $self->{MESSAGECNT} = 0;
    $self->{MSG2OCTETS} = {};
    $self->{MSG2UIDL} = {};
    $self->{MSG2URL} = {};
    $self->{MSG2ITEMDATA} = {};
    $self->{TOTALOCTETS} = 0;
    $self->{DELETE} = {};
    $self->{DELMESSAGECNT} = 0;
    $self->{DELTOTALOCTETS} = 0;
    $self->{CJAR} = HTTP::Cookies->new;
    $self->{LIST_LOADED} = 0;
    $self;
}

sub lock_acquire {
    my $self = shift;
    1;
}

sub is_valid {
    my ($self, $msg) = @_;
    $self->_list_messages unless $self->{LIST_LOADED};
    $msg > 0 and $msg <= $self->{MESSAGECNT} and !$self->is_deleted($msg);
}

sub lock_release {
    my $self = shift;
    1;
}

sub uidl_list {
    my ($self, $output_fh) = @_;
    $self->_list_messages unless $self->{LIST_LOADED};
    for (1..$self->{MESSAGECNT}) {
        if (!$self->is_deleted($_)) {
            $output_fh->print("$_ $self->{MSG2UIDL}->{$_}$CRLF");
        }
    }
    $output_fh->print(".$CRLF");
}

# find relevant info about available messages
sub _list_messages {
    my $self = shift;
    my ($list_html, $list_url) = get_fill_submit(
        $self->{CJAR},
        $self->{STARTURL},
        $self->{FIELDS},
    );
    my $list_data = list_parse($list_html, $list_url, $self->{LISTRE});
    my @items;
    while (1) {
	my @theseitems = @{ $list_data->{itemurls} };
        push @items, @theseitems;
        last if $list_data->{pageno} >= $list_data->{num_pages};
#last if $list_data->{pageno} >= 1;
        ($list_html, $list_url) = redirect_cookie_loop(
            $self->{CJAR}, GET($list_data->{nextlink}), 
        );
	$list_data = list_parse($list_html, $list_url, $self->{LISTRE});
    }
    my $cnt = 0;
    for my $item (@items) {
        $cnt++;
        my $octets = $self->{MESSAGESIZE};
	my $id = $self->{ITEMURL2ID}->($item);
        $self->{MSG2OCTETS}->{$cnt} = $octets;
        $self->{MSG2UIDL}->{$cnt} = $id;
        $self->{MSG2URL}->{$cnt} = $item;
        $self->{TOTALOCTETS} += $octets;
    }
    $self->{MESSAGECNT} = $cnt;
    $self->{LIST_LOADED} = 1;
}

sub _get_itemlines {
    my ($self, $message) = @_;
    my $data = $self->{MSG2ITEMDATA}->{$message} ||
	($self->{MSG2ITEMDATA}->{$message} = $self->_get_itemdata(
	    $self->{MSG2URL}->{$message},
	));
    my $text = $self->{ITEMFORMAT}->(
	$data,
	$self->{MSG2UIDL}->{$message},
    );
    # in case formatter wrongly adds \r - EMAIL::STUFFER I'M LOOKING AT YOU
    $text =~ s#\r$##gm;
    # should truncate it below message size if bigger
    $text .= (' ' x ($self->{MESSAGESIZE} - length($text) - 2)) . "\n";
    split /\r*\n/, $text;
}

sub _get_itemdata {
    my ($self, $url) = @_;
    my $request = GET($url);
#    $request->header('referer', $url);
    my ($one_html, $one_url) = redirect_cookie_loop($self->{CJAR}, $request);
    one_parse(
	$one_html,
	$self->{ITEMRE},
	$self->{ITEMPOSTPRO},
    );
}

# $message starts at 1
sub retrieve {
    my ($self, $message, $output_fh, $mbox_destined) = @_;
    $self->_list_messages unless $self->{LIST_LOADED};
    for ($self->_get_itemlines($message)) {
        # byte-stuff lines starting with .
        s/^\./\.\./o unless $mbox_destined;
        my $line = $mbox_destined ? "$_\n" : "$_$CRLF";
        $output_fh->print($line);
    }
}

# $message starts at 1
# returns number of bytes
sub top {
    my ($self, $message, $output_fh, $body_lines) = @_;
    $self->_list_messages unless $self->{LIST_LOADED};
    my $top_bytes = 0;
    my @lines = $self->_get_itemlines($message);
    my $linecount = 0;
    # print the headers
    while ($linecount < @lines) {
        $_ = $lines[$linecount++];
        my $out = "$_$CRLF";
        $output_fh->print($out);
        $top_bytes += length($out);
        last if /^\s*$/;
    }
    my $cnt = 0;
    # print the TOP arg number of body lines
    while ($linecount < @lines) {
        $_ = $lines[$linecount++];
        ++$cnt;
        last if $cnt > $body_lines;
        # byte-stuff lines starting with .
        s/^\./\.\./o;
        my $out = "$_$CRLF";
        $output_fh->print($out);
        $top_bytes += length($out);
    }
    $output_fh->print(".$CRLF");
    $top_bytes;
}

sub is_deleted {
    my ($self, $message) = @_;
    return $self->{DELETE}->{$message};
}

sub delete {
    my ($self, $message) = @_;
    $self->{DELETE}->{$message} = 1;
    $self->{DELMESSAGECNT} += 1;
    $self->{DELTOTALOCTETS} += $self->{MSG2OCTETS}->{$message};
}

sub flush_delete { }

sub reset {
    my $self = shift;
    $self->{DELETE} = {};
    $self->{DELMESSAGECNT} = 0;
    $self->{DELTOTALOCTETS} = 0;
}

sub octets {
    my ($self, $message) = @_;
    $self->_list_messages unless $self->{LIST_LOADED};
    if (defined $message) {
        $self->{MSG2OCTETS}->{$message};
    } else {
        $self->{TOTALOCTETS} - $self->{DELTOTALOCTETS};
    }
}

sub messages {
    my ($self) = @_;
    $self->_list_messages unless $self->{LIST_LOADED};
    $self->{MESSAGECNT} - $self->{DELMESSAGECNT};
}

sub uidl {
    my ($self, $message) = @_;
    $self->_list_messages unless $self->{LIST_LOADED};
    $self->{MSG2UIDL}->{$message};
}

sub get_fill_submit {
    my ($cjar, $url, $vars, $varnamechange) = @_;
    my ($html, $real_url) = redirect_cookie_loop($cjar, GET($url));
    parse_fill_submit($cjar, $html, $real_url, $vars, $varnamechange);
}

sub parse_fill_submit {
    my ($cjar, $html, $real_url, $vars, $varnamechange) = @_;
    my $form = HTML::Form->parse($html, $real_url);
    map {
	$form->value($_, $vars->{$_});
    } keys %$vars;
    $formno++;
    to_file("f$formno.wri", Data::Dumper::Dumper($varnamechange, $form)) if $DEBUG;
    map {
        my $input = $form->find_input(undef, undef, $_);
        $input->name($varnamechange->{$_});
        local $^W = 0; # don't want to hear about "readonly"
        $input->value('') unless defined $input->value;
    } keys %$varnamechange
        if $varnamechange;
    to_file("f$formno-after.wri", Data::Dumper::Dumper($varnamechange, $form)) if $DEBUG;
    my $form_html;
    ($form_html, $real_url) = redirect_cookie_loop(
        $cjar,
        $form->click,
    );
    ($form_html, $real_url);
}

# special case - nextlink value will be absolutised
# special case - itemurls value will be listref of absolutised values
sub list_parse {
    my ($text, $pageurl, $listre) = @_;
    my %list;
    for my $key (keys %$listre) {
        if ($key eq 'itemurls') {
            my @hits = map {
                URI::URL->new($_, $pageurl)->abs->as_string;
            } $text =~ m#$listre->{$key}#gsi;
            $list{$key} = \@hits;
        } else {
            my ($match) = $text =~ m#$listre->{$key}#si;
            $list{$key} = decode_entities($match);
        }
    }
    $list{nextlink} = URI::URL->new($list{nextlink}, $pageurl)->abs->as_string;
    \%list;
}

sub one_parse {
    my ($text, $scrapespec, $scrapepostpro) = @_;
    my %item;
    for my $key (keys %$scrapespec) {
        my ($match) = $text =~ m#$scrapespec->{$key}#si;
        $match = '' unless defined $match;
        $item{$key} = decode_entities($match);
    }
    # postpro - sub that returns list of key => value
    #   might be more than one pair
    for my $key (keys %$scrapepostpro) {
        my %ret = $scrapepostpro->{$key}->($key, $item{$key});
        map { $item{$_} = $ret{$_} } keys %ret;
    }
    \%item;
}

# modify input $cjar, return also a $response
sub redirect_cookie_loop {
    my ($cjar, $request) = @_;
    # otherwise cookies set during redirects get lost...
    my $ua = LWP::UserAgent::RedirectNotOk->new;
    $ua->agent('Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0)');
    my $response;
    while (1) {
        $req_count++;
        $cjar->add_cookie_header($request);
        print "req $req_count: ", $request->uri, "\n" if $DEBUG;
        to_file("r${req_count}req.wri", $request->as_string) if $DEBUG;
        $response = $ua->request($request);
        to_file("r${req_count}resp.wri", $response->as_string) if $DEBUG;
        unless ($response->is_success or $response->is_redirect) {
            my $text = $response->error_as_HTML;
            $text =~ s/\s+$//;
            die "Request: ".$request->as_string."\nFailed: $text\n";
        }
        $cjar->extract_cookies($response);
        my $new_loc;
        if ($response->is_redirect) {
#print "302\n";
            $new_loc = $response->header('location');
        } elsif ($response->header('refresh')) {
#print "refresh\n";
            $new_loc = parse_refresh($response->header('refresh'));
        } else {
            last;
        }
#use Data::Dumper; print Dumper($response);
        $request = GET(URI::URL->new($new_loc, $request->uri)->abs->as_string);
    }
    ($response->content, $response->request->uri->as_string);
}

sub parse_refresh {
    my $header_val = shift;
    my ($url) = $header_val =~ m#url=['"]?([^'"\s]*)#i;
    $url;
}

1;

__END__

=head1 NAME

Mail::POP3::Folder::webscrape - class that makes a website look like a
POP3 mailbox

=head1 SYNOPSIS

  use Mail::POP3;
  my $m = Mail::POP3::Folder::webscrape->new(
    $user_name,
    $password,
    $starturl, # where the first form is found
    $userfieldnames, # listref same order as values supplied in USER
    $otherfields, # hash fieldname => value
    $listre, # field => RE; fields: pageno, num_pages, nextlink, itemurls
    $itemre, # hash extractfield => RE to get it from "page"
    $itempostpro, # extractfield => sub returns pairS of field/value
    $itemurl2id, # sub taking URL, returns unique, persistent item ID
    $itemformat, # takes item hash, returns email message
    $messagesize,
  );

=head1 DESCRIPTION

This class makes a website look like a POP3 mailbox in accordance with the
requirements of a L<Mail::POP3> server. It is entirely API-compatible with
L<Mail::POP3::Folder::mbox>.

The virtual e-mails will all be at least (the amount specified in
the last parameter to C<new> - recommend 2000) octets long, being padded
to this length. While it should truncate if necessary, the class currently
does not.

=head1 PARAMETERS

=over 5

=item C<$user_name>

The username is interpreted as a ":"-separated string, also "URL-encoded"
such that spaces are encoded as "+" characters. The values supplied will
be for variables named in the C<$userfieldnames> parameter.

=item C<$password>

The password is ignored.

=item C<$starturl>

The webpage that contains the initial search form.

=item C<$userfieldnames>

A reference to a list of the names of CGI variables whose values are
supplied by the POP3 user in the username.

=item C<$otherfields>

Reference to hash of CGI field mapped to value.

=item C<$listre>

Reference to hash of fieldname mapped to regular expression for finding
the relevant value on each search result page. The value is expected to
be in C<$1>. These fields must be defined: C<pageno>, C<num_pages>,
C<nextlink>, C<itemurls>. The last may (obviously) match more than once.

=item C<$itemre>

Reference to hash of fieldname mapped to regular expression for finding
the relevant value on each item's page (as linked to by an C<itemurl>
as found from the above parameter), similar to the above. Any number
of fields may be sought, and a hash of the fieldname to the found value
will be passed to the item-formatting function below.

=item C<$itempostpro>

Reference to hash of fieldname mapped to reference to function that is
called with the field name and value, and will return a list of one or
more pairs of fieldname / value. Typical use might be to remove HTML
from a result.

=item C<$itemurl2id>

Reference to function that is called with each C<itemurl>, and will
return a unique, persistent identifier for that item, compatible with
an RFC 1939 message ID.

=item C<$itemformat>

Reference to function that is called for each item, taking two parameters:
a reference to a hash of fieldname / value (as extracted by the "item RE"
above), and the unique message-ID (as generated above); and will return
the text of an email message describing that item.

=item C<$messagesize>

The size of each message, in the style of Procrustes. This is so the class
can return an accurate(ish) result for the POP3 command STAT knowing
only the number of hits there have been, and not having downloaded and
formatted every single item to see how large each one is - such an extra
step would probably trigger timeouts.

=back

A script C<webscrape> is supplied in the C<scripts> subdirectory of the
distribution that can be used to test and develop a working configuration
for this class.

=head1 METHODS

None extra are defined.

=head1 SEE ALSO

RFC 1939, L<Mail::POP3::Folder::mbox>.
