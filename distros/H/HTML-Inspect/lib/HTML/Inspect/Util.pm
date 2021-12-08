# Copyrights 2021 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution HTML::Inspect.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

### This package contains a few generic helper functions.

use strict;
use warnings;
use utf8;

package HTML::Inspect::Util;
use vars '$VERSION';
$VERSION = '1.00';

use parent 'Exporter';

our @EXPORT_OK = qw(trim_attr xpc_find get_attributes absolute_url);

use Log::Report 'html-inspect';

use HTML::Inspect::Normalize qw(normalize_url);
use URI          ();
use Encode       qw(encode_utf8 _utf8_on is_utf8);
use XML::LibXML  ();

# Deduplicate white spaces and trim string.
sub trim_attr($) { ($_[0] // '') =~ s/\s+/ /grs =~ s/^ //r =~ s/ \z//r }

# function xpc_find($pattern)
# Precompiled xpath expressions to be reused by instances of this class.
# Not much more faster than literal string passing but still faster.
# See xt/benchmark_collectOpenGraph.pl

# state $find = xpc_find 'pattern';
# my @nodes = $find->($self);     # or even: $self->$find

sub xpc_find($) {
    my $pattern  = shift;
    my $compiled = XML::LibXML::XPathExpression->new($pattern);
    sub { $_[0]->_xpc->findnodes($compiled) };    # Call with $self as param
}

# function get_attributes($element)
# Returns a HASH of all attributes found for an HTML element, which is an
# XML::LibXML::Element.

sub get_attributes($) {
    +{ map +($_->name => trim_attr($_->value)), $_[0]->attributes };
}

# function absolute_url($relative_url, $base)
# Convert a (possible relatative) url into an absolute version.  Things
# which are not urls will return nothing.

# See https://github.com/Skrodon/temporary-documentation/wiki/HTML-link-statics
# to see what we try to clean-up here.

my %take_schemes = map +($_ => 1), qw/mailto http https ftp tel/;

sub absolute_url($$) {
    my ($href, $base) = @_;

    my $scheme = $href =~ /^([^a-z0]+)\:/i ? lc($1) : undef;
    ! $scheme || $take_schemes{$scheme}
        or return ();

    my $url;
    if(!$scheme || $scheme eq 'https' || $scheme eq 'http') {
        my ($abs, $rc, $msg) = normalize_url $href;
        return $abs if defined $abs;

        warn "$rc: $msg\n    $href\n";
        return ();
    }
    else {
        # about 2.2% of the links
        $url = URI->new_abs($href, $base)->canonical;
        $url->fragment(undef);
        return $url->as_string;
    }
}

1;
