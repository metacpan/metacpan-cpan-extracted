package EV::WebKit::Client::Element;
use v5.10;
use strict;
use warnings;

our $VERSION = '0.04';

# A remote element. The real EV::WebKit::Element lives in the browser process;
# this is a handle to it, and the same methods, each one an el.* request.
#
# The handle is only valid until the page navigates: the browser's element
# registry stamps every handle with the document's epoch, so a handle from a page
# that has gone away answers 'stale element' rather than quietly reading the
# wrong node. The server frees them at the same moment, for the same reason.

sub _new { bless { c => $_[1], h => $_[2] }, $_[0] }

sub handle { $_[0]{h} }

# text/html/value/tag/attr/prop/is_visible/click/focus/type/clear/submit all take
# (@args, $cb?) and return a plain value. find/find_all return handles, so they
# are generated separately below.
for my $m (qw(text html value tag attr prop is_visible click focus type clear submit
              scroll_into_view hover box check uncheck select_option send_keys)) {
    no strict 'refs';
    *{__PACKAGE__ . "::$m"} = sub {
        my $self = shift;
        return $self->{c}->_call("el.$m", [@_], $self->{h});
    };
}

for my $m (qw(find find_all)) {
    no strict 'refs';
    *{__PACKAGE__ . "::$m"} = sub {
        my $self = shift;
        return $self->{c}->_call_el("el.$m", [@_], $self->{h});
    };
}

sub release {
    my $self = shift;
    # [@_], like every generated method above: passing [] discarded the caller's
    # trailing callback before _cb could find it, so in ev mode -- which requires
    # one -- every spelling of release croaked, and from inside another callback
    # that croak is only a warn while the handle is never freed.
    return $self->{c}->_call('el.release', [@_], $self->{h});
}

1;

__END__

=head1 NAME

EV::WebKit::Client::Element - a remote element handle

=head1 DESCRIPTION

What L<EV::WebKit::Client>'s C<find>, C<find_all>, C<find_js>, C<find_all_js>
and C<wait_for> give you. It has the same
methods as L<EV::WebKit::Element> -- C<text>, C<html>, C<value>, C<tag>, C<attr>,
C<prop>, C<box>, C<is_visible>, C<click>, C<focus>, C<hover>, C<type>,
C<send_keys>, C<clear>, C<check>, C<uncheck>, C<select_option>,
C<scroll_into_view>, C<submit>, C<find>, C<find_all> -- and each one is a
request to the browser process. C<handle> is the id the browser knows it by.
C<frame_id> is the one local accessor with no counterpart here: it reads state
the browser process holds, and a remote handle does not carry it.

    use v5.10;                 # for say()
    my $el = $c->find('h1');
    say $el->text;

A handle stops working when the page navigates: it answers C<'stale element'>,
exactly as an in-process handle does, rather than quietly reading the wrong node
on the new page.

C<release> frees the handle in the browser process early. You rarely need it --
navigating frees them all, and so does disconnecting.

=cut
