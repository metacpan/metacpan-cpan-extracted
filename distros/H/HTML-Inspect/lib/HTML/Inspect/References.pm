# Copyrights 2021 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution HTML::Inspect.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

### This module handles the extract of any kind of reference: links
### to other pages or itself.

use strict;
use warnings;
use utf8;

package HTML::Inspect;
use vars '$VERSION';
$VERSION = '1.00';
    # Mixin

use Log::Report 'html-inspect';
use HTML::Inspect::Util qw(xpc_find absolute_url);
use List::Util   qw(uniq);

# A map: for which tag which attributes to be considered as links?
# We can add more tags and types of links later.
my %referencing_attrs = (
    a      => 'href',
    area   => 'href',
    base   => 'href',     # could be kept from the start, would add complexity
    embed  => 'src',
    form   => 'action',
    iframe => 'src',
    img    => 'src',
    link   => 'href',     # could use collectLinks(), but probably slower by complexity
    script => 'src',
);

sub collectReferences(%) {
    my ($self, %filter) = @_;
    my $refs = $self->{HIR_refs} ||= {};
    return $refs if $self->{HIR_refs_complete} && ! keys %filter;

    $self->{HIR_refs_complete}++;
    my %refs;
    while (my ($tag, $attr) = each %referencing_attrs) {
       $refs{"$tag\_$attr"} = $self->collectReferencesFor($tag, $attr, %filter);
    }
    \%refs;
}

my %find_attr;
sub collectReferencesFor($$%) {
    my ($self, $tag, $attr, %filter) = @_;
    my $label = $tag . '_' . $attr;

    # First get the full list of urls
    my $data  = $self->{HIR_refs}{$label} ||=
       do { my $find = $find_attr{$label} ||= xpc_find "//$tag\[\@$attr\]";
            [ uniq map absolute_url($_->getAttribute($attr), $self->base),
                 $find->($self)
            ];
          };

    keys %filter or return $data;
    my $all = $data;

    $data = [ grep /^https?\:/, @$data ] if $filter{http_only};
    $data = [ grep /^mailto\:/, @$data ] if $filter{mailto_only};
    $data = [ grep $_ =~ $filter{matching}, @$data ] if $filter{matching};

    if(my $max = $filter{maximum_set}) {
        $data = [ @{$data}[0..$max-1] ];  # need copy because of cache
    }

    # When no modification, then return original to reduce copies.
    @$data==@$all ? $all : $data;
}

1;
