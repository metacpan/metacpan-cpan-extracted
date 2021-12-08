# Copyrights 2021 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution HTML::Inspect.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

package HTML::Inspect;
use vars '$VERSION';
$VERSION = '1.00';


use strict;
use warnings;
use utf8;

use Log::Report 'html-inspect';

use HTML::Inspect::Util       qw(trim_attr xpc_find get_attributes absolute_url);
use HTML::Inspect::Normalize  qw(set_page_base);

use HTML::Inspect::Links      ();    # mixin for collectLink*()
use HTML::Inspect::OpenGraph  ();    # mixin for collectOpenGraph()
use HTML::Inspect::Meta       ();    # mixin for collectMeta*()
use HTML::Inspect::References ();    # mixin for collectRef*()

use XML::LibXML ();
use Scalar::Util qw(blessed);
use URI ();


sub new {
    my $class = shift;
    (bless {}, $class)->_init( {@_} );
}

my $find_base_href = xpc_find '//base[@href][1]';
sub _init($) {
    my ($self, $args) = @_;

    my $html_ref = $args->{html_ref} or panic "html_ref is required";
    ref $html_ref eq 'SCALAR'        or panic "html_ref not SCALAR";
    $$html_ref =~ m!\<\s*/?\s*\w+!   or error "Not HTML: '" . substr($$html_ref, 0, 20) . "'";

    my $req = $args->{location}      or panic '"location" is mandatory';
    my $loc = $self->{HI_location} = blessed $req ? $req : URI->new($req);

    my $dom = XML::LibXML->load_html(
        string            => $html_ref,
        recover           => 2,
        suppress_errors   => 1,
        suppress_warnings => 1,
        no_network        => 1,
        no_xinclude_nodes => 1,
    );

    my $doc = $self->{HI_doc} = $dom->documentElement;
    $self->{HI_xpc} = XML::LibXML::XPathContext->new($doc);

    ### Establish the base for relative links.

    my ($base, $rc, $err);
    if(my ($base_elem) = $find_base_href->($self)) {
        ($base, $rc, $err) = set_page_base $base_elem->getAttribute('href');
        unless($base) {
            warning __x"Illegal base href '{href}' in {url}: {err}",
                href => $base_elem->getAttribute('href'), url => $loc, err => $err;
        }
    }
    else {
        my ($base, $rc, $err) = set_page_base $loc->as_string;
        unless($base) {
            warning __x"Illegal page location '{url}': {err}", url => $loc, err => $err;
            return ();
        }
    }
    $self->{HI_base} = URI->new($base);   # base needed for other protocols (ftp)

    $self;
}

#-------------------------


sub location() { $_[0]->{HI_location} }


sub base() { $_[0]->{HI_base} }

# The root XML::LibXML::Element of the current document.
sub _doc() { $_[0]->{HI_doc} }

# Returns the XPathContext for the current document.  Used via ::Util::xpc_find
sub _xpc() { $_[0]->{HI_xpc} }

#-------------------------


# All collectLinks* in the ::Links.pm mixin


# All collectMeta* in ::Meta.pm mixin


### collectReferences*() are in mixin file ::References


### collectOpenGraph() is in mixin file ::OpenGraph


1;
